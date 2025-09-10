# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.4.0] - 2025-09-10
### Added
- **Schema (Issue 1)**: `churn.customers` (UUID PK + `external_id`, demographics/plan fields, JSONB `attributes`, timestamps) and **`churn.churn_labels`** (PK `(customer_id, label_date)`), indexes and triggers.
- **Transform Spec & Data Contracts (Issue 2)**: Kaggle-only mapping (`customers.csv`, `churn_labels.csv`) and `docs/data_contracts.md` defining exact headers & types.
- **Loader (Issue 3)**: `src/pipelines/ingest_csv.py` — env-driven (reads `.env`), supports `--data-dir` and `--full-refresh`; upserts customers by `external_id`; inserts/updates labels; skips label orphans.
- **Validation (Issue 4)**: `sql/010_validation.sql` covering row counts, orphaned labels, and churn snapshot on the latest `label_date`.
- **Make targets**: `e2e`, `e2e-v`, `validate`, `validate-all`, plus convenience targets (`db-ready`, `db-psql`, etc.).
- **README**: Make-centric quick start, sanity checks, and v0.4.0 validation runbook.

### Changed
- Prefer Make targets over raw `docker compose` commands in docs and examples.
- `counts` Make target now reports only `customers` and `churn_labels`.

### Removed
- **Events**: All references to `events.csv` and `churn.events` (schema, docs, loader, validation) to keep v0.4.0 strictly Kaggle-only.

## [0.3.0] - 2025-09-06
### Added
- Docker Compose stack (Python app + Postgres), health checks, and Make targets.
- Basic CLI health probe.

## [0.2.0] - 2025-09-05
### Added
- Repository structure, Python/SQL layout, environment templates.

## [0.1.0] - 2025-09-02 (Pre-release)
### Added
- Stabilized baseline and changelog initialization.
