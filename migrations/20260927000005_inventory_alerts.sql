-- migrate:up

CREATE TABLE feed_items (
  id         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id  uuid NOT NULL REFERENCES tenants(id) ON DELETE RESTRICT,
  name       text NOT NULL,
  category   text,
  unit       text NOT NULL DEFAULT 'kg',
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (tenant_id, name)
);

-- Current stock levels (derived/maintained). One row per item.
CREATE TABLE feed_inventory (
  id               uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id        uuid NOT NULL REFERENCES tenants(id) ON DELETE RESTRICT,
  feed_item_id     uuid NOT NULL REFERENCES feed_items(id) ON DELETE CASCADE,
  quantity_on_hand numeric(14,3) NOT NULL DEFAULT 0,
  reorder_level    numeric(14,3) NOT NULL DEFAULT 0,
  unit_cost        numeric(14,2),
  last_restocked_at timestamptz,
  updated_at       timestamptz NOT NULL DEFAULT now(),
  UNIQUE (tenant_id, feed_item_id)
);

CREATE TRIGGER trg_feed_inventory_updated BEFORE UPDATE ON feed_inventory
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- Append-only movement ledger; feed_inventory.quantity_on_hand is rolled up from this.
CREATE TABLE stock_movements (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id    uuid NOT NULL REFERENCES tenants(id) ON DELETE RESTRICT,
  feed_item_id uuid NOT NULL REFERENCES feed_items(id) ON DELETE RESTRICT,
  movement_type stock_movement_type NOT NULL,
  quantity     numeric(14,3) NOT NULL,
  reason       text,
  occurred_at  timestamptz NOT NULL DEFAULT now(),
  recorded_by  uuid REFERENCES users(id) ON DELETE SET NULL,
  created_at   timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE stock_alerts (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id    uuid NOT NULL REFERENCES tenants(id) ON DELETE RESTRICT,
  feed_item_id uuid NOT NULL REFERENCES feed_items(id) ON DELETE CASCADE,
  message      text NOT NULL,
  is_resolved  boolean NOT NULL DEFAULT false,
  created_at   timestamptz NOT NULL DEFAULT now(),
  resolved_at  timestamptz
);

CREATE TABLE reorder_suggestions (
  id                 uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id          uuid NOT NULL REFERENCES tenants(id) ON DELETE RESTRICT,
  feed_item_id       uuid NOT NULL REFERENCES feed_items(id) ON DELETE CASCADE,
  suggested_quantity numeric(14,3) NOT NULL,
  reason             text,
  status             text NOT NULL DEFAULT 'open',
  created_at         timestamptz NOT NULL DEFAULT now()
);

-- migrate:down
DROP TABLE IF EXISTS reorder_suggestions;
DROP TABLE IF EXISTS stock_alerts;
DROP TABLE IF EXISTS stock_movements;
DROP TABLE IF EXISTS feed_inventory;
DROP TABLE IF EXISTS feed_items;
