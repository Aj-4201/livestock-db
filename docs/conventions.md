# Database conventions

## Naming

- Tables: `snake_case`, **plural** (`animals`, `health_records`).
- Columns: `snake_case`, singular (`tag_number`, `date_of_birth`).
- Primary key: always `id uuid` (`gen_random_uuid()`).
- Foreign keys: `<referenced_singular>_id` (`animal_id`, `tenant_id`).
- Timestamps: `created_at`, `updated_at`, `occurred_at`, `recorded_at` — all `timestamptz`.
- Booleans: `is_*` / `has_*` (`is_active`, `is_resolved`).
- Enums: `snake_case` type names; lowercase values (`animal_origin = purchased|local|newborn`).

## Required columns

Every business table has:

| column       | type          | notes                                   |
|--------------|---------------|-----------------------------------------|
| `id`         | `uuid`        | PK, `gen_random_uuid()`                 |
| `tenant_id`  | `uuid`        | FK `tenants(id)`, indexed               |
| `created_at` | `timestamptz` | `default now()`                         |
| `updated_at` | `timestamptz` | only on mutable tables (trigger-managed)|

## Append-only tables

`health_records`, `stock_movements`, `transactions`, `audit_log` are **immutable**.
- No `updated_at`, no `UPDATE`/`DELETE` from application code.
- Corrections are new rows referencing the original (`corrects_id`).
- Read "current state" from the views in `0009_views_indexes.sql`.

## Money & quantities

- Money: `numeric(14,2)`, always paired with a `currency` (`char(3)`, default `KES`).
- Quantities: `numeric(14,3)` to allow partial feed units (kg, bales, litres).

## Indexing

- Always index `tenant_id` and every FK.
- Unique constraints are scoped per tenant, e.g. `unique (tenant_id, tag_number)`.
