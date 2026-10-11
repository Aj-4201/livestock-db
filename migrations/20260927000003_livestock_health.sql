-- migrate:up

-- Reference table (system + tenant breeds).
CREATE TABLE breeds (
  id         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id  uuid REFERENCES tenants(id) ON DELETE CASCADE,  -- NULL = system breed
  name       text NOT NULL,
  species    text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE animals (
  id             uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id      uuid NOT NULL REFERENCES tenants(id) ON DELETE RESTRICT,
  tag_number     text NOT NULL,
  name           text,
  species        text NOT NULL DEFAULT 'cattle',
  breed_id       uuid REFERENCES breeds(id) ON DELETE SET NULL,
  sex            animal_sex NOT NULL DEFAULT 'unknown',
  date_of_birth  date,
  origin         animal_origin NOT NULL DEFAULT 'newborn',
  dam_id         uuid REFERENCES animals(id) ON DELETE SET NULL,   -- mother
  sire_id        uuid REFERENCES animals(id) ON DELETE SET NULL,   -- father
  status         animal_status NOT NULL DEFAULT 'active',
  purchase_price numeric(14,2),
  purchase_date  date,
  created_by     uuid REFERENCES users(id) ON DELETE SET NULL,
  created_at     timestamptz NOT NULL DEFAULT now(),
  updated_at     timestamptz NOT NULL DEFAULT now(),
  UNIQUE (tenant_id, tag_number)
);

CREATE TRIGGER trg_animals_updated BEFORE UPDATE ON animals
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- Append-only: never UPDATE/DELETE. Back-traceable medical history.
CREATE TABLE health_records (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id    uuid NOT NULL REFERENCES tenants(id) ON DELETE RESTRICT,
  animal_id    uuid NOT NULL REFERENCES animals(id) ON DELETE RESTRICT,
  event_type   health_event_type NOT NULL,
  occurred_at  timestamptz NOT NULL DEFAULT now(),
  diagnosis    text,
  treatment    text,
  medication   text,
  dosage       text,
  vet_name     text,
  cost         numeric(14,2),
  currency     char(3) NOT NULL DEFAULT 'KES',
  notes        text,
  corrects_id  uuid REFERENCES health_records(id) ON DELETE SET NULL,
  recorded_by  uuid REFERENCES users(id) ON DELETE SET NULL,
  created_at   timestamptz NOT NULL DEFAULT now()
);

-- migrate:down
DROP TABLE IF EXISTS health_records;
DROP TABLE IF EXISTS animals;
DROP TABLE IF EXISTS breeds;
