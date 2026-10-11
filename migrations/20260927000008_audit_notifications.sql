-- migrate:up

-- Append-only audit trail. Visibility restricted to owner/manager via RBAC.
CREATE TABLE audit_log (
  id            bigserial PRIMARY KEY,
  tenant_id     uuid REFERENCES tenants(id) ON DELETE SET NULL,
  actor_user_id uuid REFERENCES users(id) ON DELETE SET NULL,
  action        text NOT NULL,              -- 'login', 'insert', 'update', 'delete'
  entity_type   text,                       -- 'health_records', 'invoices', ...
  entity_id     text,
  old_values    jsonb,
  new_values    jsonb,
  ip_address    inet,
  user_agent    text,
  occurred_at   timestamptz NOT NULL DEFAULT now()
);

-- Notification queue (delivery handled by the backend notification service).
CREATE TABLE notifications (
  id                 uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id          uuid NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  recipient_user_id  uuid REFERENCES users(id) ON DELETE SET NULL,
  channel            notification_channel NOT NULL,
  subject            text,
  body               text NOT NULL,
  status             notification_status NOT NULL DEFAULT 'pending',
  related_entity_type text,
  related_entity_id  text,
  scheduled_at       timestamptz,
  sent_at            timestamptz,
  created_at         timestamptz NOT NULL DEFAULT now()
);

-- Rules that generate alerts (vaccination due, breeding cycle, low stock...).
CREATE TABLE alert_rules (
  id             uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id      uuid NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  name           text NOT NULL,
  event_type     text NOT NULL,   -- 'vaccination_due' | 'low_stock' | 'breeding_cycle'
  channel        notification_channel NOT NULL DEFAULT 'sms',
  lead_time_days integer NOT NULL DEFAULT 0,
  is_active      boolean NOT NULL DEFAULT true,
  created_at     timestamptz NOT NULL DEFAULT now()
);

-- migrate:down
DROP TABLE IF EXISTS alert_rules;
DROP TABLE IF EXISTS notifications;
DROP TABLE IF EXISTS audit_log;
