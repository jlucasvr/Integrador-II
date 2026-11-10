CREATE TABLE municipalities (id text PRIMARY KEY, name text NOT NULL);
CREATE TABLE users (
    id text PRIMARY KEY, name text NOT NULL, email text NOT NULL UNIQUE,
    password_hash text NOT NULL, role text NOT NULL CHECK (role IN ('manager', 'municipality')),
    municipality_id text REFERENCES municipalities(id)
);
CREATE TABLE institutions (
    id text PRIMARY KEY, name text NOT NULL, municipality_id text NOT NULL REFERENCES municipalities(id),
    status text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'verified', 'suspended'))
);
CREATE TABLE memberships (
    user_id text REFERENCES users(id), institution_id text REFERENCES institutions(id),
    PRIMARY KEY (user_id, institution_id)
);
CREATE TABLE points (
    id text PRIMARY KEY, institution_id text NOT NULL REFERENCES institutions(id),
    name text NOT NULL, address text NOT NULL, region text NOT NULL, hours text NOT NULL,
    latitude double precision NOT NULL CHECK (latitude BETWEEN -90 AND 90),
    longitude double precision NOT NULL CHECK (longitude BETWEEN -180 AND 180),
    active smallint NOT NULL DEFAULT 1 CHECK (active IN (0, 1)),
    contact text NOT NULL DEFAULT '', version integer NOT NULL DEFAULT 0 CHECK (version >= 0)
);
CREATE TABLE point_creations (
    user_id text NOT NULL REFERENCES users(id), request_key text NOT NULL, request_hash text NOT NULL,
    point_id text NOT NULL REFERENCES points(id), PRIMARY KEY (user_id, request_key)
);
CREATE TABLE items (
    id text PRIMARY KEY, name text NOT NULL, category text NOT NULL, unit text NOT NULL
);
CREATE TABLE stocks (
    id text PRIMARY KEY, point_id text NOT NULL REFERENCES points(id), item_id text NOT NULL REFERENCES items(id),
    quantity integer NOT NULL CHECK (quantity BETWEEN 0 AND 1000000000),
    public_quantity smallint NOT NULL DEFAULT 1 CHECK (public_quantity IN (0, 1)),
    visible smallint NOT NULL DEFAULT 1 CHECK (visible IN (0, 1)),
    distributable smallint NOT NULL DEFAULT 1 CHECK (distributable IN (0, 1)),
    accepts_donation smallint NOT NULL DEFAULT 1 CHECK (accepts_donation IN (0, 1)),
    version integer NOT NULL DEFAULT 0 CHECK (version >= 0), updated_at timestamptz NOT NULL,
    UNIQUE (point_id, item_id)
);
CREATE TABLE sessions (
    token_hash text PRIMARY KEY, user_id text NOT NULL REFERENCES users(id), expires_at bigint NOT NULL
);
CREATE TABLE movements (
    id text PRIMARY KEY, stock_id text NOT NULL REFERENCES stocks(id), user_id text NOT NULL REFERENCES users(id),
    type text NOT NULL CHECK (type IN ('entry', 'exit', 'adjustment')),
    quantity integer NOT NULL CHECK (quantity BETWEEN 0 AND 1000000000),
    previous_balance integer NOT NULL CHECK (previous_balance BETWEEN 0 AND 1000000000),
    resulting_balance integer NOT NULL CHECK (resulting_balance BETWEEN 0 AND 1000000000),
    note text NOT NULL, created_at timestamptz NOT NULL,
    sequence bigint GENERATED ALWAYS AS IDENTITY
);
CREATE TABLE verification_events (
    id text PRIMARY KEY, institution_id text NOT NULL REFERENCES institutions(id),
    user_id text NOT NULL REFERENCES users(id), status text NOT NULL CHECK (status IN ('pending', 'verified', 'suspended')),
    note text NOT NULL, created_at timestamptz NOT NULL
);

CREATE INDEX institutions_municipality_idx ON institutions (municipality_id);
CREATE INDEX points_institution_idx ON points (institution_id);
CREATE INDEX sessions_expiration_idx ON sessions (expires_at);
CREATE INDEX movements_stock_history_idx ON movements (stock_id, created_at DESC, sequence DESC);
