import express from "express";
import helmet from "helmet";
import { rateLimit } from "express-rate-limit";
import { createHash, randomBytes } from "node:crypto";
import { newId, hashPassword, verifyPassword } from "./credentials.js";

const normalize = (value) =>
  value
    .toLowerCase()
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "")
    .trim();
const hashToken = (value) => createHash("sha256").update(value).digest("hex");
const dummyHash = hashPassword("timing-protection-not-an-account");
function fail(status, code, message) {
  const error = new Error(message);
  error.status = status;
  error.code = code;
  throw error;
}
function text(value, field, max = 150) {
  if (typeof value !== "string" || !value.trim() || value.length > max)
    fail(
      400,
      "VALIDATION_ERROR",
      `${field}: texto obrigatório de até ${max} caracteres.`,
    );
  return value.trim();
}
function integer(value, field) {
  if (!Number.isSafeInteger(value) || value < 0 || value > 1000000000)
    fail(400, "VALIDATION_ERROR", `${field}: inteiro entre 0 e 1000000000.`);
  return value;
}
function origin(query) {
  if (query.lat === undefined && query.lon === undefined) return null;
  const coordinate = (value) => {
    if (typeof value === "number") return value;
    if (typeof value === "string" && value.trim()) return Number(value);
    return NaN;
  };
  const lat = coordinate(query.lat), lon = coordinate(query.lon);
  if (
    !Number.isFinite(lat) ||
    !Number.isFinite(lon) ||
    Math.abs(lat) > 90 ||
    Math.abs(lon) > 180
  ) {
    fail(400, "VALIDATION_ERROR", "Informe lat e lon válidos juntos.");
  }
  return { lat, lon };
}
function distance(a, b) {
  if (!a) return null;
  const radians = (v) => (v * Math.PI) / 180;
  const h =
    Math.sin(radians(b.latitude - a.lat) / 2) ** 2 +
    Math.cos(radians(a.lat)) *
      Math.cos(radians(b.latitude)) *
      Math.sin(radians(b.longitude - a.lon) / 2) ** 2;
  return (
    Math.round(6371 * 2 * Math.asin(Math.sqrt(Math.min(1, h))) * 100) / 100
  );
}
async function publicPoints(db, from, id) {
  const rows = await db.all(
    `SELECT p.*, i.name AS institution, s.id AS stock_id, s.quantity,
      s.public_quantity, s.distributable, s.accepts_donation, s.updated_at,
      t.name AS item_name, t.category, t.unit
    FROM points p JOIN institutions i ON i.id=p.institution_id
    LEFT JOIN stocks s ON s.point_id=p.id AND s.visible=1
    LEFT JOIN items t ON t.id=s.item_id
    WHERE p.active=1 AND i.status='verified'${id === undefined ? "" : " AND p.id=?"}
    ORDER BY p.name, p.id, t.name, s.id`,
    ...(id === undefined ? [] : [id]),
  );
  const points = new Map();
  for (const row of rows) {
    if (!points.has(row.id)) {
      points.set(row.id, {
        id: row.id, name: row.name, institution: row.institution,
        address: row.address, region: row.region, hours: row.hours,
        contact: row.contact, latitude: row.latitude, longitude: row.longitude,
        distanceKm: distance(from, row), updatedAt: "", resources: [],
      });
    }
    if (row.stock_id === null) continue;
    const point = points.get(row.id);
    const updatedAt = new Date(row.updated_at).toISOString();
    if (updatedAt > point.updatedAt) point.updatedAt = updatedAt;
    point.resources.push({
      id: row.stock_id, name: row.item_name, category: row.category, unit: row.unit,
      available: Boolean(row.distributable && row.quantity > 0),
      acceptsDonation: Boolean(row.accepts_donation),
      publicQuantity: row.public_quantity ? row.quantity : null,
      updatedAt,
    });
  }
  return [...points.values()];
}

export function createApp(db, { allowedOrigins = [], localOrigins = true, trustProxy = false, demo = false, logger } = {}) {
  const app = express();
  app.disable("x-powered-by");
  app.set("trust proxy", trustProxy);
  app.use((req, res, next) => {
    const start = performance.now();
    req.id = newId();
    res.set("X-Request-Id", req.id);
    res.on("finish", () => logger?.info(JSON.stringify({
      level: "info", event: "http_request", requestId: req.id,
      method: req.method, route: req.route?.path, status: res.statusCode,
      durationMs: Math.round(performance.now() - start),
    })));
    next();
  });
  app.use(helmet());
  app.use((req, res, next) => {
    const o = req.headers.origin;
    const allowed = allowedOrigins.length
      ? allowedOrigins.includes(o)
      : localOrigins && /^http:\/\/(localhost|127\.0\.0\.1):\d+$/.test(o ?? "");
    if (o && !allowed)
      return res
        .status(403)
        .json({
          error: { code: "ORIGIN_DENIED", message: "Origem não autorizada." },
        });
    if (o) {
      res.set("Access-Control-Allow-Origin", o);
      res.vary("Origin");
    }
    res.set("Access-Control-Allow-Headers", "Content-Type, Authorization, Idempotency-Key");
    res.set("Access-Control-Expose-Headers", "X-Request-Id");
    res.set("Access-Control-Allow-Methods", "GET, POST, PATCH, OPTIONS");
    res.set("Cache-Control", "no-store");
    if (req.method === "OPTIONS") return res.sendStatus(204);
    next();
  });
  app.use(express.json({ limit: "32kb", inflate: false }));
  const authenticate = async (req, res, next) => {
    const token = req.headers.authorization?.match(
      /^Bearer ([A-Za-z0-9_-]{43})$/,
    )?.[1];
    if (!token)
      return next(
        Object.assign(new Error("Entre na sua conta."), {
          status: 401,
          code: "UNAUTHORIZED",
        }),
      );
    const user = await db.get(`SELECT u.id,u.name,u.email,u.role,u.municipality_id FROM sessions s JOIN users u ON u.id=s.user_id
      WHERE s.token_hash=? AND s.expires_at>?`, hashToken(token), Date.now());
    if (!user)
      return next(
        Object.assign(new Error("Sessão inválida ou expirada."), {
          status: 401,
          code: "UNAUTHORIZED",
        }),
      );
    req.user = user;
    req.tokenHash = hashToken(token);
    next();
  };
  function municipality(user) {
    if (user.role !== "municipality")
      fail(403, "FORBIDDEN", "Acesso restrito à prefeitura.");
  }
  async function canManage(user, pointId) {
    if (
      user.role !== "manager" ||
      !await db.get(`SELECT 1 FROM memberships m JOIN points p ON p.institution_id=m.institution_id
      WHERE m.user_id=? AND p.id=?`, user.id, pointId)
    )
      fail(403, "FORBIDDEN", "Você não administra este ponto.");
  }
  app.get("/api/v1/health", async (req, res) =>
    res.json({ status: "ok", version: "0.1.0" }),
  );
  app.get("/api/v1/ready", async (req, res) => {
    try {
      await db.checkReady();
      res.json({ status: "ready" });
    } catch {
      logger?.error(JSON.stringify({ level: "error", event: "database_unavailable", requestId: req.id }));
      res.status(503).json({ status: "unavailable" });
    }
  });
  app.get("/api/v1/points", async (req, res) => {
    const q = normalize(text(req.query.q, "q", 100));
    if (!q) fail(400, "VALIDATION_ERROR", "Informe um item ou categoria.");
    const intent = req.query.intent ?? "help";
    if (!["help", "donate"].includes(intent))
      fail(400, "VALIDATION_ERROR", "intent deve ser help ou donate.");
    const from = origin(req.query);
    const location =
      req.query.location === undefined
        ? ""
        : normalize(text(req.query.location, "location", 150));
    const radius =
      req.query.radiusKm === undefined ? null : Number(req.query.radiusKm);
    if (
      radius !== null &&
      (!from || !Number.isFinite(radius) || radius <= 0 || radius > 500)
    )
      fail(
        400,
        "VALIDATION_ERROR",
        "radiusKm exige coordenadas e valor entre 0 e 500.",
      );
    if (
      req.query.availableOnly !== undefined &&
      !["true", "false"].includes(req.query.availableOnly)
    )
      fail(400, "VALIDATION_ERROR", "availableOnly deve ser true ou false.");
    const points = (await publicPoints(db, from))
      .filter(
        (p) =>
          !location ||
          location
            .split(",")
            .every((part) =>
              normalize(`${p.region} ${p.address}`).includes(part.trim()),
            ),
      )
      .filter((p) => radius === null || p.distanceKm <= radius);
    const eligible = (r) =>
      (intent === "help" || r.acceptsDonation) &&
      (req.query.availableOnly !== "true" ||
        intent === "donate" ||
        r.available);
    const collectHits = (matches, alternative) => points.flatMap((point) => {
      const candidates = point.resources.filter((r) => eligible(r) && matches(r));
      const resource = intent === "help"
        ? candidates.find((r) => r.available) ?? candidates[0]
        : candidates[0];
      return resource ? [{ point, resource, alternative }] : [];
    });
    let hits = collectHits(
      (r) => normalize(r.name).includes(q) || normalize(r.category) === q,
      false,
    );
    if (!hits.length) {
      const category = {
        "agua mineral": "Água",
        comida: "Alimentos",
        sabonete: "Higiene",
        agasalho: "Abrigo",
      }[q];
      if (category) hits = collectHits((r) => r.category === category, true);
    }
    hits.sort(
      (a, b) =>
        Number(b.resource.available) - Number(a.resource.available) ||
        (a.point.distanceKm ?? Infinity) - (b.point.distanceKm ?? Infinity) ||
        a.point.name.localeCompare(b.point.name, "pt-BR"),
    );
    res.json({
      data: hits,
      meta: {
        total: hits.length,
        sort: from ? "availability_distance_name" : "availability_name",
        distanceCalculated: Boolean(from),
        demo,
      },
    });
  });
  app.get("/api/v1/points/:id", async (req, res) => {
    const [p] = await publicPoints(db, origin(req.query), req.params.id);
    if (!p) fail(404, "NOT_FOUND", "Ponto não encontrado.");
    res.json({ data: p });
  });
  app.post(
    "/api/v1/auth/login",
    rateLimit({
      windowMs: 15 * 60 * 1000,
      limit: 20,
      standardHeaders: "draft-8",
      legacyHeaders: false,
      handler: (_req, res) => res.status(429).json({
        error: { code: "RATE_LIMITED", message: "Muitas tentativas. Tente novamente mais tarde." },
      }),
    }),
    async (req, res) => {
      const email = text(req.body?.email, "email", 254).toLowerCase();
      text(req.body?.password, "password", 256);
      const password = req.body.password;
      const user = await db.get("SELECT * FROM users WHERE email=?", email);
      const valid = await verifyPassword(password, user?.password_hash ?? dummyHash);
      if (!user || !valid)
        fail(401, "INVALID_CREDENTIALS", "E-mail ou senha inválidos.");
      const token = randomBytes(32).toString("base64url"),
        expiresAt = Date.now() + 8 * 60 * 60 * 1000;
      await db.run("DELETE FROM sessions WHERE expires_at<=?", Date.now());
      await db.run("INSERT INTO sessions VALUES (?,?,?)", hashToken(token),
        user.id,
        expiresAt,
      );
      res.json({
        data: {
          token,
          expiresAt: new Date(expiresAt).toISOString(),
          user: {
            id: user.id,
            name: user.name,
            email: user.email,
            role: user.role,
          },
        },
      });
    },
  );
  app.get("/api/v1/auth/me", authenticate, async (req, res) =>
    res.json({ data: req.user }),
  );
  app.post("/api/v1/auth/logout", authenticate, async (req, res) => {
    await db.run("DELETE FROM sessions WHERE token_hash=?", req.tokenHash);
    res.sendStatus(204);
  });
  app.get("/api/v1/manage/points", authenticate, async (req, res) => {
    if (req.user.role !== "manager")
      fail(403, "FORBIDDEN", "Acesso restrito ao gestor.");
    res.json({
      data: await db.all(`SELECT p.*,i.name AS institution FROM points p JOIN institutions i ON i.id=p.institution_id
      JOIN memberships m ON m.institution_id=p.institution_id
      WHERE m.user_id=? ORDER BY p.name`, req.user.id),
    });
  });
  app.get('/api/v1/manage/my-institutions', authenticate, async (req, res) => {
    if (req.user.role !== 'manager') fail(403, 'FORBIDDEN', 'Acesso restrito ao gestor.');
    res.json({data: await db.all(`SELECT i.id,i.name FROM institutions i JOIN memberships m ON m.institution_id=i.id WHERE m.user_id=? ORDER BY i.name`, req.user.id)});
  });
  function pointFields(b) {
    const coords = origin({lat: b.latitude, lon: b.longitude});
    if (!coords || typeof b.latitude !== 'number' || typeof b.longitude !== 'number') fail(400, 'VALIDATION_ERROR', 'Informe latitude e longitude numéricas.');
    if (typeof b.active !== 'boolean') fail(400, 'VALIDATION_ERROR', 'Informe se o ponto está ativo.');
    if (typeof b.contact !== 'string' || b.contact.length > 250) fail(400, 'VALIDATION_ERROR', 'Contato deve ter até 250 caracteres.');
    return [text(b.name,'Nome'), text(b.address,'Endereço',300), text(b.region,'Região'), text(b.hours,'Horário',250), coords.lat, coords.lon, Number(b.active), b.contact.trim()];
  }
  app.post('/api/v1/manage/points', authenticate, async (req, res) => {
    const b = req.body ?? {};
    if (req.user.role !== 'manager') fail(403, 'FORBIDDEN', 'Acesso restrito ao gestor.');
    const institutionId = text(b.institution_id, 'institution_id');
    const key = req.get('Idempotency-Key');
    if (key !== undefined && !/^[A-Za-z0-9_-]{1,128}$/.test(key)) {
      fail(400, 'VALIDATION_ERROR', 'Chave de cadastro inválida.');
    }

    async function createPoint(tx) {
      if (!await tx.get('SELECT 1 FROM memberships WHERE user_id=? AND institution_id=?', req.user.id, institutionId)) {
        fail(403, 'FORBIDDEN', 'Você não administra esta instituição.');
      }
      const values = pointFields(b);
      const fingerprint = key && createHash('sha256')
        .update(JSON.stringify([institutionId, ...values])).digest('hex');
      if (key) {
        const saved = await tx.get('SELECT point_id, request_hash FROM point_creations WHERE user_id=? AND request_key=?', req.user.id, key);
        if (saved) {
          if (saved.request_hash !== fingerprint) {
            fail(409, 'IDEMPOTENCY_CONFLICT', 'Esta tentativa já foi usada com outros dados. Confira a lista de pontos.');
          }
          return saved.point_id;
        }
      }

      const id = newId();
      await tx.run(`INSERT INTO points(id,institution_id,name,address,region,hours,latitude,longitude,active,contact)
        VALUES (?,?,?,?,?,?,?,?,?,?)`, id, institutionId, ...values);
      if (key) {
        await tx.run('INSERT INTO point_creations(user_id, request_key, request_hash, point_id) VALUES (?,?,?,?)', req.user.id, key, fingerprint, id);
      }
      return id;
    }

    const id = key
      ? await db.transaction(async (tx) => {
          await tx.getForUpdate("SELECT id FROM users WHERE id=?", req.user.id);
          return createPoint(tx);
        })
      : await createPoint(db);
    res.status(201).json({ data: { id } });
  });
  app.patch('/api/v1/manage/points/:id', authenticate, async (req, res) => {
    await canManage(req.user,req.params.id);
    const b = req.body ?? {}, values = pointFields(b);
    const version = integer(b.expectedVersion,'expectedVersion');
    const result = await db.run('UPDATE points SET name=?,address=?,region=?,hours=?,latitude=?,longitude=?,active=?,contact=?,version=version+1 WHERE id=? AND version=?', ...values,req.params.id,version);
    if (!result.changes) fail(409,'STALE_POINT','Ponto atualizado por outro gestor. Volte à lista e recarregue antes de editar.');
    res.json({data:{id:req.params.id,version:version+1}});
  });
  app.get("/api/v1/manage/points/:id/stock", authenticate, async (req, res) => {
    await canManage(req.user, req.params.id);
    res.json({
      data: await db.all(`SELECT s.*,i.name,i.category,i.unit FROM stocks s JOIN items i ON i.id=s.item_id
      WHERE s.point_id=? ORDER BY i.name`, req.params.id),
    });
  });
  app.get("/api/v1/manage/points/:id/catalog", authenticate, async (req, res) => {
    const pointId = req.params.id;
    await canManage(req.user, pointId);
    const data = await db.all(`
      SELECT i.id, i.name, i.category, i.unit FROM items i
      WHERE NOT EXISTS (
        SELECT 1 FROM stocks s WHERE s.point_id=? AND s.item_id=i.id
      ) ORDER BY i.name, i.id
    `, pointId);
    res.json({ data });
  });
  app.post("/api/v1/manage/points/:id/stock", authenticate, async (req, res) => {
    const pointId = req.params.id;
    await canManage(req.user, pointId);
    const itemId = text(req.body?.item_id, "item_id");
    if (!await db.get("SELECT 1 FROM items WHERE id=?", itemId)) {
      fail(404, "CATALOG_ITEM_NOT_FOUND", "Item não encontrado no catálogo.");
    }

    const id = newId();
    const result = await db.run(`
      INSERT INTO stocks(id, point_id, item_id, quantity, public_quantity,
        visible, distributable, accepts_donation, version, updated_at)
      VALUES (?, ?, ?, 0, 0, 0, 0, 0, 0, ?)
      ON CONFLICT(point_id, item_id) DO NOTHING
    `, id, pointId, itemId, new Date().toISOString());
    if (!result.changes) {
      fail(409, "ITEM_ALREADY_LINKED", "Este item já está vinculado ao estoque deste ponto.");
    }
    res.status(201).json({ data: { id } });
  });
  async function managedStock(req) {
    const stock = await db.get("SELECT * FROM stocks WHERE id=?", req.params.id);
    if (!stock) fail(404, "NOT_FOUND", "Item de estoque não encontrado.");
    await canManage(req.user, stock.point_id);
    return stock;
  }
  app.post("/api/v1/manage/stocks/:id/movements", authenticate, async (req, res) => {
    const s = await managedStock(req),
      body = req.body ?? {};
    if (!["entry", "exit", "adjustment"].includes(body.type))
      fail(400, "VALIDATION_ERROR", "type deve ser entry, exit ou adjustment.");
    const quantity = integer(body.quantity, "quantity");
    const version = integer(body.expectedVersion, "expectedVersion");
    if (body.type !== "adjustment" && quantity === 0)
      fail(
        400,
        "VALIDATION_ERROR",
        "Entrada e saída exigem quantidade positiva.",
      );
    const note = body.note === undefined ? "" : text(body.note, "note", 500);
    const movement = await db.transaction(async (tx) => {
      const current = await tx.getForUpdate("SELECT * FROM stocks WHERE id=?", s.id);
      if (current.version !== version)
        fail(
          409,
          "STALE_STOCK",
          "Estoque atualizado por outro gestor. Recarregue o saldo.",
        );
      const balance =
        body.type === "adjustment"
          ? quantity
          : current.quantity + (body.type === "entry" ? quantity : -quantity);
      if (balance < 0)
        fail(409, "INSUFFICIENT_STOCK", "A saída excede o saldo disponível.");
      if (balance > 1000000000)
        fail(400, "VALIDATION_ERROR", "Saldo máximo excedido.");
      const createdAt = new Date().toISOString(),
        id = newId();
      await tx.run("UPDATE stocks SET quantity=?,version=version+1,updated_at=? WHERE id=?", balance, createdAt, s.id);
      await tx.run("INSERT INTO movements(id,stock_id,user_id,type,quantity,previous_balance,resulting_balance,note,created_at) VALUES (?,?,?,?,?,?,?,?,?)", id,
        s.id,
        req.user.id,
        body.type,
        quantity,
        current.quantity,
        balance,
        note,
        createdAt,
      );
      return {
        id, previousBalance: current.quantity, resultingBalance: balance,
        version: version + 1, createdAt,
      };
    });
    res.status(201).json({ data: movement });
  });
  app.get("/api/v1/manage/stocks/:id/movements", authenticate, async (req, res) => {
    const s = await managedStock(req);
    res.json({
      data: await db.all(`SELECT m.id,m.stock_id,m.user_id,m.type,m.quantity,m.previous_balance,m.resulting_balance,m.note,m.created_at,u.name AS user_name FROM movements m JOIN users u ON u.id=m.user_id
      WHERE m.stock_id=? ORDER BY m.created_at DESC, ${db.historyOrder} DESC LIMIT 100`, s.id),
    });
  });
  app.patch(
    "/api/v1/manage/stocks/:id/publication",
    authenticate,
    async (req, res) => {
      const s = await managedStock(req),
        b = req.body ?? {};
      const fields = [
        "public_quantity",
        "visible",
        "distributable",
        "accepts_donation",
      ];
      if (fields.some((k) => typeof b[k] !== "boolean"))
        fail(
          400,
          "VALIDATION_ERROR",
          "Informe os quatro campos de publicação como booleanos.",
        );
      const version = integer(b.expectedVersion, "expectedVersion");
      const result = await db.run(`UPDATE stocks SET public_quantity=?,visible=?,distributable=?,accepts_donation=?,
      version=version+1,updated_at=? WHERE id=? AND version=?`, ...fields.map((k) => Number(b[k])),
          new Date().toISOString(),
          s.id,
          version,
        );
      if (!result.changes)
        fail(
          409,
          "STALE_STOCK",
          "Recarregue o estoque antes de alterar a publicação.",
        );
      res.json({ data: { version: version + 1 } });
    },
  );
  app.get("/api/v1/manage/institutions", authenticate, async (req, res) => {
    municipality(req.user);
    res.json({
      data: await db.all("SELECT * FROM institutions WHERE municipality_id=? ORDER BY name", req.user.municipality_id),
    });
  });
  app.post("/api/v1/manage/institutions", authenticate, async (req, res) => {
    municipality(req.user);
    const id = newId(),
      name = text(req.body?.name, "name");
    await db.run("INSERT INTO institutions VALUES (?,?,?,?)", id,
      name,
      req.user.municipality_id,
      "pending",
    );
    res.status(201).json({ data: { id, name, status: "pending" } });
  });
  app.patch(
    "/api/v1/manage/institutions/:id/verification",
    authenticate,
    async (req, res) => {
      municipality(req.user);
      const i = await db.get("SELECT * FROM institutions WHERE id=? AND municipality_id=?", req.params.id, req.user.municipality_id);
      if (!i)
        fail(404, "NOT_FOUND", "Instituição não encontrada nesta prefeitura.");
      const { status, note } = req.body ?? {};
      if (!["pending", "verified", "suspended"].includes(status))
        fail(400, "VALIDATION_ERROR", "Situação inválida.");
      const reason = text(note, "note", 500);
      await db.transaction(async (tx) => {
        await tx.run("UPDATE institutions SET status=? WHERE id=?", status,
          i.id,
        );
        await tx.run("INSERT INTO verification_events VALUES (?,?,?,?,?,?)", newId(),
          i.id,
          req.user.id,
          status,
          reason,
          new Date().toISOString(),
        );
      });
      res.json({ data: { id: i.id, status } });
    },
  );
  app.use(async (req, res) =>
    res
      .status(404)
      .json({ error: { code: "NOT_FOUND", message: "Rota não encontrada." } }),
  );
  app.use((error, req, res, next) => {
    if (res.headersSent) return next(error);
    const status = error.status ?? 500;
    if (status >= 500) logger?.error(JSON.stringify({
      level: "error", event: "request_error", requestId: req.id, code: error.code,
    }));
    res
      .status(status)
      .json({
        error: {
          code:
            status >= 500 ? "INTERNAL_ERROR" : error.code ?? (status === 400 ? "INVALID_JSON" : "REQUEST_ERROR"),
          message:
            status >= 500 ? "Falha interna. Tente novamente." : error.message,
        },
      });
  });
  return app;
}
