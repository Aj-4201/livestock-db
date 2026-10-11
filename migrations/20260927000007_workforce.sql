-- migrate:up

CREATE TABLE workers (
  id         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id  uuid NOT NULL REFERENCES tenants(id) ON DELETE RESTRICT,
  user_id    uuid REFERENCES users(id) ON DELETE SET NULL,  -- optional login
  full_name  text NOT NULL,
  phone      text,
  role_title text,
  hired_date date,
  is_active  boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now()
);

-- Manager-entered, worker-acknowledged attendance.
CREATE TABLE attendance (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id       uuid NOT NULL REFERENCES tenants(id) ON DELETE RESTRICT,
  worker_id       uuid NOT NULL REFERENCES workers(id) ON DELETE CASCADE,
  work_date       date NOT NULL,
  status          attendance_status NOT NULL DEFAULT 'present',
  check_in        timestamptz,
  check_out       timestamptz,
  recorded_by     uuid REFERENCES users(id) ON DELETE SET NULL,  -- manager
  acknowledged_by uuid REFERENCES users(id) ON DELETE SET NULL,  -- worker
  acknowledged_at timestamptz,
  notes           text,
  created_at      timestamptz NOT NULL DEFAULT now(),
  UNIQUE (tenant_id, worker_id, work_date)
);

-- migrate:down
DROP TABLE IF EXISTS attendance;
DROP TABLE IF EXISTS workers;
