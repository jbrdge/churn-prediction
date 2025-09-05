# Changelog
All notable changes to this project are documented here.  
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and uses [Semantic Versioning](https://semver.org/).

---

## [0.1.0] - 2025-09-02 (Pre-release)

### Added
- Initial stabilized baseline of the project
- Archived legacy notebook under `notebooks/legacy/` (deprecated but runnable)
- Basic GitHub Actions workflow for linting/tests (CI starter)

### Removed
- Deleted `sql/02_sanity_checks_and_baseline.sql` (legacy, no longer needed)

### Fixed
- Broken import/path issue
- Stray inline reviewer comment
- Env/file reference alignment

### Notes
- Pre-release baseline before code-first + Docker restructure
- Roadmap: `ops/repo-structure` → `ops/docker-compose` → `feat/sql-etl` → `feat/model-baseline` → `viz/tableau-dashboard`

---

## [0.2.0] - Unreleased
### Planned
- Introduce clear Python/SQL repo structure
- Add env templates

## Project Structure (v0.2.0)
```
churn-prediction/
├── .github/
│   ├── workflows/
│   │   └── ci.yml
│   └── PULL_REQUEST_TEMPLATE.md
├── data/
│   ├── archive/
│   │   └── Telco-Customer-Churn.csv
│   ├── processed/
│   │   └── .gitkeep
│   └── raw/
│       └── .gitkeep
├── notebooks/
│   ├── artifacts/
│   │   └── model_card.json
│   ├── legacy/
│   │   └── churn_regression.ipynb
│   └── .gitkeep
├── scripts/
│   └── load_csv.sh
├── sql/
│   ├── queries/
│   │   └── sample_churn_report.sql
│   └── 001_schema.sql
├── src/
│   ├── pipelines/
│   │   └── ingest_csv.py
│   ├── __init__.py
│   ├── config.py
│   └── db.py
├── tests/
│   └── test_db.py
├── .env.example
├── .gitattributes
├── .gitignore
├── CHANGELOG.md
├── docker-compose.yml
├── environment.yml
├── LICENSE
├── Makefile
├── README.md
├── requirements.txt
└── VERSION
```

---

## [0.3.0] - Unreleased
### Planned
- Add Dockerfile + docker-compose.yml
- Include health checks and Makefile targets

---

## [0.4.0] - Unreleased
### Planned
- Implement SQL schema + ETL loader

---

## [0.5.0] - Unreleased
### Planned
- Provide baseline churn model CLI
- Save artifacts and metrics

---

## [0.6.0] - Unreleased
### Planned
- Publish Tableau dashboard to Tableau Public
- Add link and screenshots to READMEgit checkout -b docs/add-tableau-milestone