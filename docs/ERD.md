# Entity Relationship Diagram

```mermaid
erDiagram
    tenants ||--o{ users : has
    tenants ||--o{ animals : owns
    tenants ||--o{ feed_items : owns
    tenants ||--o{ invoices : issues
    tenants ||--o{ workers : employs

    users }o--o{ roles : "user_roles"
    roles }o--o{ permissions : "role_permissions"

    animals ||--o{ health_records : "health (append-only)"
    animals ||--o{ breeding_events : "dam/sire"
    animals }o--|| breeds : breed

    feed_items ||--o{ stock_movements : "in/out (append-only)"
    feed_items ||--o{ stock_alerts : raises
    feed_items ||--o{ reorder_suggestions : suggests

    invoices ||--o{ invoice_items : contains
    invoices ||--o{ installments : "paid via"
    tenants ||--o{ transactions : "ledger (append-only)"
    tenants ||--o{ budgets : plans

    workers ||--o{ attendance : logs
    tenants ||--o{ audit_log : "audit (append-only)"
    tenants ||--o{ notifications : sends
    tenants ||--o{ alert_rules : configures
```

## Notes

- `animals.dam_id` / `animals.sire_id` are self-references (mother / father) enabling lineage.
- `origin` distinguishes `purchased` vs `local` vs `newborn` (breeding module requirement).
- Attendance is manager-entered (`recorded_by`) and worker-acknowledged (`acknowledged_by`).
- Audit and health history are restricted to owner/manager roles via RBAC (see migration 0002).
