-- migrate:up

-- Append-only financial ledger (income/expense). Source of truth for reports/forecasting.
CREATE TABLE transactions (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id   uuid NOT NULL REFERENCES tenants(id) ON DELETE RESTRICT,
  txn_type    txn_type NOT NULL,
  amount      numeric(14,2) NOT NULL CHECK (amount >= 0),
  currency    char(3) NOT NULL DEFAULT 'KES',
  category    text,
  description text,
  reference   text,
  occurred_at timestamptz NOT NULL DEFAULT now(),
  recorded_by uuid REFERENCES users(id) ON DELETE SET NULL,
  created_at  timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE invoices (
  id             uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id      uuid NOT NULL REFERENCES tenants(id) ON DELETE RESTRICT,
  invoice_number text NOT NULL,
  customer_name  text NOT NULL,
  issue_date     date NOT NULL DEFAULT CURRENT_DATE,
  due_date       date,
  total_amount   numeric(14,2) NOT NULL DEFAULT 0,
  currency       char(3) NOT NULL DEFAULT 'KES',
  status         invoice_status NOT NULL DEFAULT 'draft',
  notes          text,
  created_by     uuid REFERENCES users(id) ON DELETE SET NULL,
  created_at     timestamptz NOT NULL DEFAULT now(),
  updated_at     timestamptz NOT NULL DEFAULT now(),
  UNIQUE (tenant_id, invoice_number)
);

CREATE TABLE invoice_items (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  invoice_id  uuid NOT NULL REFERENCES invoices(id) ON DELETE CASCADE,
  description text NOT NULL,
  quantity    numeric(14,3) NOT NULL DEFAULT 1,
  unit_price  numeric(14,2) NOT NULL DEFAULT 0
);

-- Installment / payment tracking against an invoice.
CREATE TABLE installments (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id   uuid NOT NULL REFERENCES tenants(id) ON DELETE RESTRICT,
  invoice_id  uuid NOT NULL REFERENCES invoices(id) ON DELETE CASCADE,
  amount      numeric(14,2) NOT NULL CHECK (amount >= 0),
  due_date    date,
  paid_date   date,
  status      installment_status NOT NULL DEFAULT 'pending',
  method      text,
  reference   text,
  created_at  timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE budgets (
  id             uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id      uuid NOT NULL REFERENCES tenants(id) ON DELETE RESTRICT,
  name           text NOT NULL,
  category       text,
  period_start   date NOT NULL,
  period_end     date NOT NULL,
  planned_amount numeric(14,2) NOT NULL DEFAULT 0,
  created_at     timestamptz NOT NULL DEFAULT now(),
  CHECK (period_end >= period_start)
);

CREATE TRIGGER trg_invoices_updated BEFORE UPDATE ON invoices
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- migrate:down
DROP TABLE IF EXISTS budgets;
DROP TABLE IF EXISTS installments;
DROP TABLE IF EXISTS invoice_items;
DROP TABLE IF EXISTS invoices;
DROP TABLE IF EXISTS transactions;
