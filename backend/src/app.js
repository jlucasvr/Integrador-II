import express from 'express';
import helmet from 'helmet';
import { rateLimit } from 'express-rate-limit';
import { createHash, randomBytes } from 'node:crypto';
import { newId, hashPassword, verifyPassword } from './database.js';

const normalize = value => value.toLowerCase().normalize('NFD').replace(/[\u0300-\u036f]/g,'').trim();
const hashToken = value => createHash('sha256').update(value).digest('hex');
const dummyHash = hashPassword('timing-protection-not-an-account');
function fail(status, code, message) { const error = new Error(message); error.status=status; error.code=code; throw error; }
function text(value, field, max=150) {
  if(typeof value!=='string'||!value.trim()||value.length>max) fail(400,'VALIDATION_ERROR',`${field}: texto obrigatório de até ${max} caracteres.`);
  return value.trim();
}
function integer(value, field) {
  if(!Number.isSafeInteger(value)||value<0||value>1000000000) fail(400,'VALIDATION_ERROR',`${field}: inteiro entre 0 e 1000000000.`);
  return value;
}
function origin(query) {
  if(query.lat===undefined && query.lon===undefined) return null;
  const lat=Number(query.lat),lon=Number(query.lon);
  if(query.lat===undefined||query.lon===undefined||query.lat===''||query.lon===''||!Number.isFinite(lat)||!Number.isFinite(lon)||Math.abs(lat)>90||Math.abs(lon)>180) {
    fail(400,'VALIDATION_ERROR','Informe lat e lon válidos juntos.');
  }
  return {lat,lon};
}
function distance(a,b) {
  if(!a) return null;
  const radians=v=>v*Math.PI/180;
  const h=Math.sin(radians(b.latitude-a.lat)/2)**2+
    Math.cos(radians(a.lat))*Math.cos(radians(b.latitude))*Math.sin(radians(b.longitude-a.lon)/2)**2;
  return Math.round(6371*2*Math.asin(Math.sqrt(Math.min(1,h)))*100)/100;
}
function publicPoint(db, id, from=null) {
  const p=db.prepare(`SELECT p.*,i.name AS institution FROM points p JOIN institutions i ON i.id=p.institution_id
    WHERE p.id=? AND p.active=1 AND i.status='verified'`).get(id);
  if(!p) return null;
  const resources=db.prepare(`SELECT s.id,s.quantity,s.public_quantity,s.distributable,s.accepts_donation,s.updated_at,
    t.name,t.category,t.unit FROM stocks s JOIN items t ON t.id=s.item_id WHERE s.point_id=? AND s.visible=1 ORDER BY t.name`).all(id);
  return {id:p.id,name:p.name,institution:p.institution,address:p.address,region:p.region,hours:p.hours,
    latitude:p.latitude,longitude:p.longitude,distanceKm:distance(from,p),
    updatedAt:resources.reduce((last,r)=>r.updated_at>last?r.updated_at:last,''),
    resources:resources.map(r=>({id:r.id,name:r.name,category:r.category,unit:r.unit,
      available:Boolean(r.distributable&&r.quantity>0),acceptsDonation:Boolean(r.accepts_donation),
      publicQuantity:r.public_quantity?r.quantity:null,updatedAt:r.updated_at}))};
}

export function createApp(db,{allowedOrigins=[]}={}) {
  const app=express();
  app.disable('x-powered-by');
  app.use(helmet());
  app.use((req,res,next)=>{
    const o=req.headers.origin;
    const allowed=allowedOrigins.length?allowedOrigins.includes(o):/^http:\/\/(localhost|127\.0\.0\.1):\d+$/.test(o??'');
    if(o&&!allowed) return res.status(403).json({error:{code:'ORIGIN_DENIED',message:'Origem não autorizada.'}});
    if(o) { res.set('Access-Control-Allow-Origin',o); res.vary('Origin'); }
    res.set('Access-Control-Allow-Headers','Content-Type, Authorization');
    res.set('Access-Control-Allow-Methods','GET, POST, PATCH, OPTIONS');
    res.set('Cache-Control','no-store');
    if(req.method==='OPTIONS') return res.sendStatus(204);
    next();
  });
  app.use(express.json({limit:'32kb'}));
  const authenticate=(req,res,next)=>{
    const token=req.headers.authorization?.match(/^Bearer ([A-Za-z0-9_-]{43})$/)?.[1];
    if(!token) return next(Object.assign(new Error('Entre na sua conta.'),{status:401,code:'UNAUTHORIZED'}));
    const user=db.prepare(`SELECT u.id,u.name,u.email,u.role,u.municipality_id FROM sessions s JOIN users u ON u.id=s.user_id
      WHERE s.token_hash=? AND s.expires_at>?`).get(hashToken(token),Date.now());
    if(!user) return next(Object.assign(new Error('Sessão inválida ou expirada.'),{status:401,code:'UNAUTHORIZED'}));
    req.user=user;req.tokenHash=hashToken(token);next();
  };
  function municipality(user) { if(user.role!=='municipality') fail(403,'FORBIDDEN','Acesso restrito à prefeitura.'); }
  function canManage(user,pointId) {
    if(user.role!=='manager'||!db.prepare(`SELECT 1 FROM memberships m JOIN points p ON p.institution_id=m.institution_id
      WHERE m.user_id=? AND p.id=?`).get(user.id,pointId)) fail(403,'FORBIDDEN','Você não administra este ponto.');
  }
  app.get('/api/v1/health',(req,res)=>res.json({status:'ok',version:'0.1.0'}));
  app.get('/api/v1/points',(req,res)=>{
    const q=normalize(text(req.query.q,'q',100));
    const intent=req.query.intent??'help';
    if(!['help','donate'].includes(intent)) fail(400,'VALIDATION_ERROR','intent deve ser help ou donate.');
    const from=origin(req.query);
    const location=req.query.location===undefined?'':normalize(text(req.query.location,'location',150));
    const radius=req.query.radiusKm===undefined?null:Number(req.query.radiusKm);
    if(radius!==null&&(!from||!Number.isFinite(radius)||radius<=0||radius>500)) fail(400,'VALIDATION_ERROR','radiusKm exige coordenadas e valor entre 0 e 500.');
    if(req.query.availableOnly!==undefined&&!['true','false'].includes(req.query.availableOnly)) fail(400,'VALIDATION_ERROR','availableOnly deve ser true ou false.');
    const points=db.prepare('SELECT id FROM points ORDER BY name').all().map(({id})=>publicPoint(db,id,from)).filter(Boolean)
      .filter(p=>!location||location.split(',').every(part=>normalize(`${p.region} ${p.address}`).includes(part.trim())))
      .filter(p=>radius===null||p.distanceKm<=radius);
    const eligible=r=>(intent==='help'||r.acceptsDonation)&&
      (req.query.availableOnly!=='true'||intent==='donate'||r.available);
    let hits=points.flatMap(p=>{const r=p.resources.find(r=>eligible(r)&&(normalize(r.name).includes(q)||normalize(r.category)===q));
      return r?[{point:p,resource:r,alternative:false}]:[];});
    if(!hits.length) {
      const category={'agua mineral':'Água','comida':'Alimentos','sabonete':'Higiene','agasalho':'Abrigo'}[q];
      if(category) hits=points.flatMap(p=>{const r=p.resources.find(r=>eligible(r)&&r.category===category);
        return r?[{point:p,resource:r,alternative:true}]:[];});
    }
    hits.sort((a,b)=>Number(b.resource.available)-Number(a.resource.available)||
      (a.point.distanceKm??Infinity)-(b.point.distanceKm??Infinity)||a.point.name.localeCompare(b.point.name,'pt-BR'));
    res.json({data:hits,meta:{total:hits.length,sort:from?'availability_distance_name':'availability_name',
      distanceCalculated:Boolean(from),demo:true}});
  });
  app.get('/api/v1/points/:id',(req,res)=>{
    const p=publicPoint(db,req.params.id,origin(req.query));
    if(!p) fail(404,'NOT_FOUND','Ponto não encontrado.');res.json({data:p});
  });
  app.post('/api/v1/auth/login',rateLimit({windowMs:15*60*1000,limit:20,standardHeaders:'draft-8',legacyHeaders:false}),
    (req,res)=>{
      const email=text(req.body?.email,'email',254).toLowerCase();
      text(req.body?.password,'password',256);
      const password=req.body.password;
      const user=db.prepare('SELECT * FROM users WHERE email=?').get(email);
      const valid=verifyPassword(password,user?.password_hash??dummyHash);
      if(!user||!valid) fail(401,'INVALID_CREDENTIALS','E-mail ou senha inválidos.');
      const token=randomBytes(32).toString('base64url'),expiresAt=Date.now()+8*60*60*1000;
      db.prepare('DELETE FROM sessions WHERE expires_at<=?').run(Date.now());
      db.prepare('INSERT INTO sessions VALUES (?,?,?)').run(hashToken(token),user.id,expiresAt);
      res.json({data:{token,expiresAt:new Date(expiresAt).toISOString(),user:{id:user.id,name:user.name,email:user.email,role:user.role}}});
    });
  app.get('/api/v1/auth/me',authenticate,(req,res)=>res.json({data:req.user}));
  app.post('/api/v1/auth/logout',authenticate,(req,res)=>{db.prepare('DELETE FROM sessions WHERE token_hash=?').run(req.tokenHash);res.sendStatus(204);});
  app.get('/api/v1/manage/points',authenticate,(req,res)=>{
    if(req.user.role!=='manager') fail(403,'FORBIDDEN','Acesso restrito ao gestor.');
    res.json({data:db.prepare(`SELECT p.*,i.name AS institution FROM points p JOIN institutions i ON i.id=p.institution_id
      JOIN memberships m ON m.institution_id=p.institution_id
      WHERE m.user_id=? ORDER BY p.name`).all(req.user.id)});
  });
  app.get('/api/v1/manage/points/:id/stock',authenticate,(req,res)=>{
    canManage(req.user,req.params.id);
    res.json({data:db.prepare(`SELECT s.*,i.name,i.category,i.unit FROM stocks s JOIN items i ON i.id=s.item_id
      WHERE s.point_id=? ORDER BY i.name`).all(req.params.id)});
  });
  function managedStock(req) {
    const stock=db.prepare('SELECT * FROM stocks WHERE id=?').get(req.params.id);
    if(!stock) fail(404,'NOT_FOUND','Item de estoque não encontrado.');
    canManage(req.user,stock.point_id);return stock;
  }
  app.post('/api/v1/manage/stocks/:id/movements',authenticate,(req,res)=>{
    const s=managedStock(req),body=req.body??{};
    if(!['entry','exit','adjustment'].includes(body.type)) fail(400,'VALIDATION_ERROR','type deve ser entry, exit ou adjustment.');
    const quantity=integer(body.quantity,'quantity');
    const version=integer(body.expectedVersion,'expectedVersion');
    if(body.type!=='adjustment'&&quantity===0) fail(400,'VALIDATION_ERROR','Entrada e saída exigem quantidade positiva.');
    const note=body.note===undefined?'':text(body.note,'note',500);
    db.exec('BEGIN IMMEDIATE');
    try {
      const current=db.prepare('SELECT * FROM stocks WHERE id=?').get(s.id);
      if(current.version!==version) fail(409,'STALE_STOCK','Estoque atualizado por outro gestor. Recarregue o saldo.');
      const balance=body.type==='adjustment'?quantity:current.quantity+(body.type==='entry'?quantity:-quantity);
      if(balance<0) fail(409,'INSUFFICIENT_STOCK','A saída excede o saldo disponível.');
      if(balance>1000000000) fail(400,'VALIDATION_ERROR','Saldo máximo excedido.');
      const createdAt=new Date().toISOString(),id=newId();
      db.prepare('UPDATE stocks SET quantity=?,version=version+1,updated_at=? WHERE id=?').run(balance,createdAt,s.id);
      db.prepare('INSERT INTO movements VALUES (?,?,?,?,?,?,?,?,?)').run(id,s.id,req.user.id,body.type,quantity,current.quantity,balance,note,createdAt);
      db.exec('COMMIT');res.status(201).json({data:{id,previousBalance:current.quantity,resultingBalance:balance,version:version+1,createdAt}});
    } catch(error) {db.exec('ROLLBACK');throw error;}
  });
  app.get('/api/v1/manage/stocks/:id/movements',authenticate,(req,res)=>{
    const s=managedStock(req);
    res.json({data:db.prepare(`SELECT m.*,u.name AS user_name FROM movements m JOIN users u ON u.id=m.user_id
      WHERE m.stock_id=? ORDER BY m.created_at DESC, m.rowid DESC LIMIT 100`).all(s.id)});
  });
  app.patch('/api/v1/manage/stocks/:id/publication',authenticate,(req,res)=>{
    const s=managedStock(req),b=req.body??{};
    const fields=['public_quantity','visible','distributable','accepts_donation'];
    if(fields.some(k=>typeof b[k]!=='boolean')) fail(400,'VALIDATION_ERROR','Informe os quatro campos de publicação como booleanos.');
    const version=integer(b.expectedVersion,'expectedVersion');
    const result=db.prepare(`UPDATE stocks SET public_quantity=?,visible=?,distributable=?,accepts_donation=?,
      version=version+1,updated_at=? WHERE id=? AND version=?`).run(...fields.map(k=>Number(b[k])),new Date().toISOString(),s.id,version);
    if(!result.changes) fail(409,'STALE_STOCK','Recarregue o estoque antes de alterar a publicação.');
    res.json({data:{version:version+1}});
  });
  app.get('/api/v1/manage/institutions',authenticate,(req,res)=>{
    municipality(req.user);res.json({data:db.prepare('SELECT * FROM institutions WHERE municipality_id=? ORDER BY name').all(req.user.municipality_id)});
  });
  app.post('/api/v1/manage/institutions',authenticate,(req,res)=>{
    municipality(req.user);const id=newId(),name=text(req.body?.name,'name');
    db.prepare('INSERT INTO institutions VALUES (?,?,?,?)').run(id,name,req.user.municipality_id,'pending');
    res.status(201).json({data:{id,name,status:'pending'}});
  });
  app.patch('/api/v1/manage/institutions/:id/verification',authenticate,(req,res)=>{
    municipality(req.user);
    const i=db.prepare('SELECT * FROM institutions WHERE id=? AND municipality_id=?').get(req.params.id,req.user.municipality_id);
    if(!i) fail(404,'NOT_FOUND','Instituição não encontrada nesta prefeitura.');
    const {status,note}=req.body??{};
    if(!['pending','verified','suspended'].includes(status)) fail(400,'VALIDATION_ERROR','Situação inválida.');
    const reason=text(note,'note',500);
    db.exec('BEGIN IMMEDIATE');
    try {db.prepare('UPDATE institutions SET status=? WHERE id=?').run(status,i.id);
      db.prepare('INSERT INTO verification_events VALUES (?,?,?,?,?,?)').run(newId(),i.id,req.user.id,status,reason,new Date().toISOString());
      db.exec('COMMIT');} catch(e) {db.exec('ROLLBACK');throw e;}
    res.json({data:{id:i.id,status}});
  });
  app.use((req,res)=>res.status(404).json({error:{code:'NOT_FOUND',message:'Rota não encontrada.'}}));
  app.use((error,req,res,next)=>{
    if(res.headersSent) return next(error);
    const status=error.status??500;
    if(status>=500) console.error('API error:',error.message);
    res.status(status).json({error:{code:error.code??(status===400?'INVALID_JSON':'INTERNAL_ERROR'),
      message:status>=500?'Falha interna. Tente novamente.':error.message}});
  });
  return app;
}
