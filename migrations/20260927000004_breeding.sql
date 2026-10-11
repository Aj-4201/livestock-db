-- migrate:up

-- Breeding / reproduction events. Lineage itself lives on animals.dam_id/sire_id.
CREATE TABLE breeding_events (
  id               uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id        uuid NOT NULL REFERENCES tenants(id) ON DELETE RESTRICT,
  dam_id           uuid NOT NULL REFERENCES animals(id) ON DELETE RESTRICT,
  sire_id          uuid REFERENCES animals(id) ON DELETE SET NULL,
  event_type       breeding_event_type NOT NULL,
  occurred_at      timestamptz NOT NULL DEFAULT now(),
  expected_due_date date,
  offspring_count  integer,
  notes            text,
  recorded_by      uuid REFERENCES users(id) ON DELETE SET NULL,
  created_at       timestamptz NOT NULL DEFAULT now()
);

-- migrate:down
DROP TABLE IF EXISTS breeding_events;
