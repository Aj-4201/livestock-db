-- migrate:up
CREATE EXTENSION IF NOT EXISTS pgcrypto;   -- gen_random_uuid()
CREATE EXTENSION IF NOT EXISTS citext;     -- case-insensitive email

-- Shared trigger to keep updated_at honest on mutable tables.
CREATE OR REPLACE FUNCTION set_updated_at() RETURNS trigger AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Domain enums (kept small; extend via new migrations, never mutate in place).
CREATE TYPE animal_origin      AS ENUM ('purchased', 'local', 'newborn');
CREATE TYPE animal_sex         AS ENUM ('male', 'female', 'unknown');
CREATE TYPE animal_status      AS ENUM ('active', 'sold', 'dead', 'archived');
CREATE TYPE health_event_type  AS ENUM ('vaccination', 'treatment', 'checkup', 'illness', 'injury', 'deworming');
CREATE TYPE breeding_event_type AS ENUM ('mating', 'insemination', 'pregnancy_check', 'birth', 'abortion');
CREATE TYPE stock_movement_type AS ENUM ('in', 'out', 'adjustment');
CREATE TYPE txn_type           AS ENUM ('income', 'expense');
CREATE TYPE invoice_status     AS ENUM ('draft', 'sent', 'partial', 'paid', 'overdue', 'cancelled');
CREATE TYPE installment_status AS ENUM ('pending', 'paid', 'overdue');
CREATE TYPE attendance_status  AS ENUM ('present', 'absent', 'late', 'excused');
CREATE TYPE notification_channel AS ENUM ('sms', 'email', 'web_push', 'whatsapp');
CREATE TYPE notification_status  AS ENUM ('pending', 'sent', 'failed');

-- migrate:down
DROP TYPE IF EXISTS notification_status;
DROP TYPE IF EXISTS notification_channel;
DROP TYPE IF EXISTS attendance_status;
DROP TYPE IF EXISTS installment_status;
DROP TYPE IF EXISTS invoice_status;
DROP TYPE IF EXISTS txn_type;
DROP TYPE IF EXISTS stock_movement_type;
DROP TYPE IF EXISTS breeding_event_type;
DROP TYPE IF EXISTS health_event_type;
DROP TYPE IF EXISTS animal_status;
DROP TYPE IF EXISTS animal_sex;
DROP TYPE IF EXISTS animal_origin;
DROP FUNCTION IF EXISTS set_updated_at();
