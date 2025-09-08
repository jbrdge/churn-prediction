-- 001_schema.sql — PostgreSQL schema for churn project
-- Run inside an already-created database (compose POSTGRES_DB creates it)

CREATE SCHEMA IF NOT EXISTS churn;

-- Enable UUIDs if available (safe to keep; no-op if not installed)
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Customers
CREATE TABLE IF NOT EXISTS churn.customers (
  customer_id   UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  external_id   TEXT UNIQUE,               -- original Telco customerID
  created_at    TIMESTAMPTZ,               -- snapshot_date - tenure months
  signup_source TEXT,                      -- Contract or 'telco_import'
  country       TEXT,
  region        TEXT,
  city          TEXT,
  plan_tier     TEXT,                      -- InternetService
  is_active     BOOLEAN DEFAULT TRUE,      -- Churn == 'No'
  attributes    JSONB,                     -- packed remaining Telco fields
  inserted_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Events (synthetic signup/billing)
CREATE TABLE IF NOT EXISTS churn.events (
  event_id    BIGSERIAL PRIMARY KEY,
  customer_id UUID REFERENCES churn.customers(customer_id) ON DELETE CASCADE,
  event_type  TEXT NOT NULL,
  event_ts    TIMESTAMPTZ NOT NULL,
  properties  JSONB,
  source_file TEXT,
  inserted_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS ix_events_customer_ts ON churn.events(customer_id, event_ts DESC);
CREATE INDEX IF NOT EXISTS ix_events_type_ts    ON churn.events(event_type, event_ts DESC);

-- Churn labels (snapshot)
CREATE TABLE IF NOT EXISTS churn.churn_labels (
  customer_id UUID REFERENCES churn.customers(customer_id) ON DELETE CASCADE,
  label       BOOLEAN NOT NULL,            -- TRUE if churned by label_date
  label_date  DATE    NOT NULL,            -- snapshot date
  reason_code TEXT,
  notes       TEXT,
  inserted_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (customer_id, label_date)
);

-- updated_at trigger
CREATE OR REPLACE FUNCTION churn.set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_customers_updated_at ON churn.customers;
CREATE TRIGGER trg_customers_updated_at
BEFORE UPDATE ON churn.customers
FOR EACH ROW EXECUTE PROCEDURE churn.set_updated_at();
