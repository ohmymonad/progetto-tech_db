-- GymManager schema

CREATE TABLE IF NOT EXISTS members (
  id          SERIAL PRIMARY KEY,
  first_name  TEXT NOT NULL,
  last_name   TEXT NOT NULL,
  birth_date  DATE,
  address     TEXT,
  phone       TEXT,
  email       TEXT,
  active      BOOLEAN NOT NULL DEFAULT TRUE,
  created_at  TIMESTAMP NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS classes (
  id          SERIAL PRIMARY KEY,
  name        TEXT NOT NULL,
  description TEXT,
  schedule    TEXT,
  instructor  TEXT
);

CREATE TABLE IF NOT EXISTS enrollments (
  member_id   INTEGER NOT NULL REFERENCES members(id) ON DELETE CASCADE,
  class_id    INTEGER NOT NULL REFERENCES classes(id) ON DELETE CASCADE,
  enrolled_at TIMESTAMP NOT NULL DEFAULT now(),
  PRIMARY KEY (member_id, class_id)
);

CREATE TABLE IF NOT EXISTS attendances (
  id            SERIAL PRIMARY KEY,
  member_id     INTEGER NOT NULL REFERENCES members(id) ON DELETE CASCADE,
  checked_in_at TIMESTAMP NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_attendances_member ON attendances(member_id);
CREATE INDEX IF NOT EXISTS idx_enrollments_class ON enrollments(class_id);
