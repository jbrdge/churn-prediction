## Purpose

Define how the **Telco Customer Churn** source columns map into the warehouse schema and loader-ready CSVs. Also clarify derived fields and what goes into `attributes` JSONB.

## Source Columns (Telco)

`customerID, gender, SeniorCitizen, Partner, Dependents, tenure, PhoneService, MultipleLines, InternetService, OnlineSecurity, OnlineBackup, DeviceProtection, TechSupport, StreamingTV, StreamingMovies, Contract, PaperlessBilling, PaymentMethod, MonthlyCharges, TotalCharges, Churn`

## Warehouse Targets

- **customers**
    - `external_id`  ← `customerID`
    - `created_at`  ← **derived:** `snapshot_date − tenure months` (ISO8601)
    - `signup_source`  ← `Contract` (or literal `telco_import`)
    - `plan_tier`  ← `InternetService`
    - `is_active`  ← `Churn == "No"`
    - `country, region, city`  ← defaults `US, NA, ""` (dataset lacks geo)
    - `attributes` (JSONB) packs remaining fields:
        - `gender, SeniorCitizen, Partner, Dependents, PhoneService, MultipleLines, OnlineSecurity, OnlineBackup, DeviceProtection, TechSupport, StreamingTV, StreamingMovies, PaperlessBilling, PaymentMethod, MonthlyCharges, TotalCharges, tenure, Contract, InternetService`
- **churn_labels**
    - `customer_id`  ← resolved via `external_id`
    - `label`  ← `Churn` (Yes→true, No→false)
    - `label_date`  ← `snapshot_date` (YYYY-MM-DD)
    - `reason_code, notes`  ← blank initially


## Derived Fields
- `created_at:` computed from `tenure` relative to a chosen `snapshot_date` (see Issue 2). Example: with `snapshot_date=2024‑06‑30` and `tenure=12`, `created_at=2023‑06‑30T00:00:00Z`.
- `is_active`: `Churn == "No"` at `label_date`.

## Notes
-  Keep `TotalCharges` as a string in `attributes` at this stage (some rows are blank in source). Coercion/cleaning can be a later ETL step.
- Booleans are normalized downstream by the loader; here they remain as strings inside `attributes` JSON.
