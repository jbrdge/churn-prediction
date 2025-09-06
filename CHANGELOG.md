# Changelog
All notable changes to this project are documented here.
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and uses [Semantic Versioning](https://semver.org/).

---

## [0.6.0] - Unreleased
### Planned
- Publish Tableau dashboard to Tableau Public
- Add link and screenshots to README

## [0.5.0] - Unreleased
### Planned
- Provide baseline churn model CLI
- Save artifacts and metrics

## [0.4.0] - Unreleased
### Planned
- Implement SQL schema + ETL loader

---

## [0.3.0] - 2025-09-06
### Added
- **Dockerfile** for Python app (lean image; installs minimal runtime deps)
- **docker-compose.yml** with **PostgreSQL 16** service + robust `pg_isready` healthcheck
- **App container** kept alive for interactive exec (`sleep infinity`) and optional app healthcheck
- **`src/config.py`** (immutable settings; builds `postgresql+psycopg://` SQLAlchemy URL)
- **`src/app.py`** with `health` subcommand (prints redacted DSN; executes `SELECT 1`)
- **Makefile** targets: `up`, `down`, `down-v`, `ps`, `logs`, `app-sh`, `db-sh`, `db-psql`, `app-psql`, `health`
- **`.pre-commit-config.yaml`** (Black, Ruff, nbstripout, sanity hooks)
- **CI** step to run pre-commit hooks (`pre-commit/action@v3.0.1`)
- **`.dockerignore`** to reduce build context (exclude VCS, CI, notebooks, tests, large data)
- **`requirements-dev.txt`** for notebooks/ML stack (keeps runtime image light)

### Changed
- Switched database from **MySQL → PostgreSQL** (compose env now `POSTGRES_*`; default host port `5433`)
- Cleaned up `docker-compose.yml`:
  - removed obsolete `version:` key
  - added `depends_on: condition: service_healthy`
  - set app `command` to `sleep infinity` for stable dev workflow
- Trimmed **`requirements.txt`** to minimal runtime deps: `sqlalchemy`, `psycopg[binary]`, `python-dotenv==1.1.1`
- Dockerfile copies only `src/` into the image (code is volume-mounted in dev)

### Fixed
- Eliminated compose warnings about missing `MYSQL_*` variables
- Resolved app restart loop by not running a one-shot command as default

### Notes
- Verified: `docker compose up -d` brings up **db (healthy)** + **app**; `python -m src.app health` → **OK**
- Inside containers the DB is `db:5432`; from host use `localhost:5433` (per port mapping)
- v0.4.0 will layer schema/ingest commands onto this foundation

### Repo snapshot (selected)
```
├── Dockerfile
├── docker-compose.yml
├── .dockerignore
├── .pre-commit-config.yaml
├── requirements.txt
├── requirements-dev.txt
├── Makefile
├── src/
│ ├── app.py
│ └── config.py
└── .github/
└── workflows/
└── ci.yml
```

---

## [0.2.0] - 2025-09-05
### Added
- Introduced standardized Python/SQL repository structure
- Added environment/config templates and placeholders for `src/`, `sql/queries/`, `tests/`, and `data/`
- Added `Makefile` and `docker-compose.yml` placeholders
- Updated README with Current Milestone (v0.2.0) note

### Changed
- Renamed `sql/00_schema.sql` → `sql/001_schema.sql`

### Removed
- Deleted legacy `sql/archive/` (files retained in Git history)

### Notes
- This is a **structure-only** release; functional logic will be added in subsequent milestones.

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
