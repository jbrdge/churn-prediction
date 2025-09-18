# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.5.0] - 2025-09-12
### Added
- **Baseline modeling CLI** (`src/cli/train_baseline.py`) with reproducible artifacts:
  - `model.pkl`, `metrics.json`, `params.json`, `coefficients.csv`, `confusion_matrix.png`, `roc_curve.png`.
- **Optional sampling** via `--sample N` (deterministic pre-split cap). Value recorded in `params.json`.
- **Monte Carlo harness**: `make monte-carlo N=<rows> MC_ITERS=<k>` produces `artifacts/mc_baseline/metrics.csv` and per-run artifacts.
- **Best-run selection**: `scripts/mc_best.py` + `make mc-best [METRIC=roc_auc]` copies best run to `artifacts/mc_baseline/best/` and writes `best_summary.json`.
- **Helper scripts**: `scripts/archive_to_parquet.py`, `scripts/show_metrics.py`, `scripts/mc_append_metrics.py`, `scripts/docker-env.sh`.
- **Make targets** only (no raw Python needed): `make-features-from-archive`, `train-baseline`, `train-baseline-sample`, `show-metrics`, `ls-artifacts`, `monte-carlo`, `monte-carlo-summary`, `mc-best`, `mc-show-best`, `mc-show-best-metrics`, `mc-ls-best`.
- **Headless plotting**: configure Matplotlib backend/cache so PNG plots render in containers.
- **Permissions UX**: support running containers as host user with `user: "${HOST_UID:-1000}:${HOST_GID:-1000}"` and helper script.

### Changed
- **Makefile**: added Docker-first targets and removed fragile heredocs; use `--entrypoint sh -c`.
- **ROC plot**: save via explicit `fig, ax` to avoid blank images in headless runs.
- **Feature names**: extract from fitted `ColumnTransformer.get_feature_names_out()` for correct one-hot names.
- **Docs**: README updated to use **Make-only** commands for training and analysis; added Monte Carlo and best-run helpers.
- **Dependencies**: recommended pins in `requirements.txt` for deterministic runs (pandas, scikit-learn, matplotlib, pyarrow, joblib).

### Removed
- N/A

## [0.4.0] - 2025-09-10
### Added
- Schema (`churn.customers`, `churn.churn_labels`), CSV→Postgres loader, validation SQL.
- Make runbook targets for end-to-end validation.
### Changed
- Prefer Make targets over raw `docker compose` in docs/examples.
### Removed
- Events pipeline (kept v0.4.0 strictly Kaggle-only).

## [0.3.0] - 2025-09-06
### Added
- Docker Compose stack (Python app + Postgres), health checks, Make targets.

## [0.2.0] - 2025-09-05
### Added
- Repository structure, Python/SQL layout, environment templates.

## [0.1.0] - 2025-09-02 (Pre-release)
### Added
- Stabilized baseline and changelog initialization.
