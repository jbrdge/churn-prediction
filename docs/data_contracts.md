
## Data Contracts (loader CSV expectations)

These define the exact headers and semantics the loader expects.

### customers.csv

**Headers:** `external_id, created_at, signup_source, country, region, city, plan_tier, is_active, attributes`

**Semantics/Types:**
- `external_id`: string (unique key from Telco `customerID`)
- `created_at`: ISO8601 timestamp (e.g., `2024-06-30T00:00:00Z`)
- `signup_source`: string (`Contract` or literal `telco_import`)
- `country, region, city`: strings (defaults allowed)
- `plan_tier`: string (`InternetService`)
- `is_active`: boolean encoded as `true|false`
- `attributes`: **valid JSON string** (will be cast to JSONB)

### events.csv

**Headers:** `external_id, event_type, event_ts, properties, source_file`

**Semantics/Types:**
- `external_id`: joins to `customers.external_id`
- `event_type`: string (e.g., `signup`, `billing_cycle`)
- `event_ts`: ISO8601 timestamp
- `properties`: **valid JSON string **(nullable)
- `source_file`: string (provenance; filename okay)

### churn_labels.csv

**Headers:** `external_id, label, label_date, reason_code, notes`

**Semantics/Types:**
- `external_id`: joins to `customers.external_id`
- `label`: boolean `true|false` (Telco Churn Yes→true)
- `label_date`: `YYYY-MM-DD` (snapshot date)
- `reason_code`: string (nullable)
- `notes`: string (nullable)

## Validation Expectations
- JSON columns must be parseable; timestamps ISO8601; booleans lowercase `true|false`.
- Every `events` and `churn_labels` row should resolve to an existing `external_id` in `customers` (unknowns are skipped by loader).
