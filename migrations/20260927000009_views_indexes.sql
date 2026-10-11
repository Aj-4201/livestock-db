-- migrate:up

-- ---- Indexes -------------------------------------------------------------
CREATE INDEX idx_users_tenant            ON users (tenant_id);
CREATE INDEX idx_roles_tenant            ON roles (tenant_id);
CREATE INDEX idx_breeds_tenant           ON breeds (tenant_id);
CREATE INDEX idx_animals_tenant          ON animals (tenant_id);
CREATE INDEX idx_animals_breed           ON animals (breed_id);
CREATE INDEX idx_animals_dam             ON animals (dam_id);
CREATE INDEX idx_animals_sire            ON animals (sire_id);
CREATE INDEX idx_animals_status          ON animals (tenant_id, status);
CREATE INDEX idx_health_animal           ON health_records (animal_id, occurred_at DESC);
CREATE INDEX idx_health_tenant           ON health_records (tenant_id);
CREATE INDEX idx_breeding_dam            ON breeding_events (dam_id, occurred_at DESC);
CREATE INDEX idx_feed_items_tenant       ON feed_items (tenant_id);
CREATE INDEX idx_stock_movements_item    ON stock_movements (feed_item_id, occurred_at DESC);
CREATE INDEX idx_stock_alerts_open       ON stock_alerts (tenant_id) WHERE NOT is_resolved;
CREATE INDEX idx_transactions_tenant     ON transactions (tenant_id, occurred_at DESC);
CREATE INDEX idx_invoices_tenant         ON invoices (tenant_id, status);
CREATE INDEX idx_installments_invoice    ON installments (invoice_id, status);
CREATE INDEX idx_attendance_worker       ON attendance (tenant_id, worker_id, work_date);
CREATE INDEX idx_audit_tenant_time       ON audit_log (tenant_id, occurred_at DESC);
CREATE INDEX idx_audit_entity            ON audit_log (entity_type, entity_id);
CREATE INDEX idx_notifications_pending   ON notifications (tenant_id) WHERE status = 'pending';

-- ---- Read models (views) -------------------------------------------------

-- Latest health event per animal (history stays in the append-only table).
CREATE VIEW v_animal_current_health AS
SELECT DISTINCT ON (animal_id)
       animal_id, tenant_id, event_type, occurred_at, diagnosis, treatment, medication
FROM health_records
ORDER BY animal_id, occurred_at DESC;

-- Herd size and status breakdown per tenant.
CREATE VIEW v_herd_summary AS
SELECT tenant_id,
       count(*)                                        AS total,
       count(*) FILTER (WHERE status = 'active')       AS active,
       count(*) FILTER (WHERE status = 'sold')         AS sold,
       count(*) FILTER (WHERE status = 'dead')         AS dead,
       count(*) FILTER (WHERE sex = 'female')          AS females,
       count(*) FILTER (WHERE sex = 'male')            AS males
FROM animals
GROUP BY tenant_id;

-- Inventory at or below reorder level.
CREATE VIEW v_low_stock AS
SELECT fi.tenant_id, fi.feed_item_id, f.name, fi.quantity_on_hand, fi.reorder_level
FROM feed_inventory fi
JOIN feed_items f ON f.id = fi.feed_item_id
WHERE fi.quantity_on_hand <= fi.reorder_level;

-- Outstanding balance per invoice.
CREATE VIEW v_invoice_balance AS
SELECT i.id AS invoice_id, i.tenant_id, i.invoice_number, i.total_amount,
       COALESCE(sum(ins.amount) FILTER (WHERE ins.status = 'paid'), 0) AS amount_paid,
       i.total_amount - COALESCE(sum(ins.amount) FILTER (WHERE ins.status = 'paid'), 0) AS balance
FROM invoices i
LEFT JOIN installments ins ON ins.invoice_id = i.id
GROUP BY i.id;

-- migrate:down
DROP VIEW IF EXISTS v_invoice_balance;
DROP VIEW IF EXISTS v_low_stock;
DROP VIEW IF EXISTS v_herd_summary;
DROP VIEW IF EXISTS v_animal_current_health;
DROP INDEX IF EXISTS idx_notifications_pending;
DROP INDEX IF EXISTS idx_audit_entity;
DROP INDEX IF EXISTS idx_audit_tenant_time;
DROP INDEX IF EXISTS idx_attendance_worker;
DROP INDEX IF EXISTS idx_installments_invoice;
DROP INDEX IF EXISTS idx_invoices_tenant;
DROP INDEX IF EXISTS idx_transactions_tenant;
DROP INDEX IF EXISTS idx_stock_alerts_open;
DROP INDEX IF EXISTS idx_stock_movements_item;
DROP INDEX IF EXISTS idx_feed_items_tenant;
DROP INDEX IF EXISTS idx_breeding_dam;
DROP INDEX IF EXISTS idx_health_tenant;
DROP INDEX IF EXISTS idx_health_animal;
DROP INDEX IF EXISTS idx_animals_status;
DROP INDEX IF EXISTS idx_animals_sire;
DROP INDEX IF EXISTS idx_animals_dam;
DROP INDEX IF EXISTS idx_animals_breed;
DROP INDEX IF EXISTS idx_animals_tenant;
DROP INDEX IF EXISTS idx_breeds_tenant;
DROP INDEX IF EXISTS idx_roles_tenant;
DROP INDEX IF EXISTS idx_users_tenant;
