#!/usr/bin/env bash
set -eu
mkdir -p db/migrate
cat > db/schema.sql <<'SQL'
CREATE TABLE orders (
  id INTEGER PRIMARY KEY,
  external_ref VARCHAR(40) NOT NULL,
  total_cents INTEGER NOT NULL
);
SQL
cat > db/migrate/002_add_status.sql <<'SQL'
-- Adds a nullable status column to orders and a unique index on external_ref.
-- The index assumes the live orders table has no duplicate external_ref values.
-- This repository holds no production data, so that assumption is not checked here.
ALTER TABLE orders ADD COLUMN status VARCHAR(16);
CREATE UNIQUE INDEX orders_external_ref_idx ON orders (external_ref);
SQL
