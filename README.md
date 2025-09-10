# Customer Churn Prediction

![Version](https://img.shields.io/badge/version-0.4.0-blue.svg)
![Build](https://github.com/jbrdge/churn-prediction/actions/workflows/ci.yml/badge.svg)
![License](https://img.shields.io/badge/license-MIT-green.svg)

End-to-end churn workflow, built incrementally. As of **v0.4.0**, the project ships a **reproducible Docker dev environment** (Python + PostgreSQL), a CSV→Postgres ETL loader, and a validation runbook.

---

## Stack Overview

```text
Developer (Make/Compose)
        |
        v
+-------------------+        +--------------------------+
|   app (Python)    | <----> |   db (PostgreSQL 16)     |
|  docker container |        |   docker container       |
+-------------------+        +--------------------------+
         ^   |
         |   | reads env from `.env`
         +---+ (POSTGRES_*; DATABASE_URL)
```

- **Python 3.11** (lean runtime): SQLAlchemy + psycopg v3
- **PostgreSQL 16 (alpine)** with `pg_isready` healthcheck
- **Docker Compose** for orchestration
- **Makefile** for all workflows (build, load, validate, clean, etc.)
- **pre-commit + GitHub Actions** for formatting, linting, and notebook output stripping

---

## Quick Start (Docker + Make, recommended)

```bash
# 1) Clone and configure env
git clone https://github.com/jbrdge/churn-prediction.git
cd churn-prediction
cp .env.example .env   # contains POSTGRES_* keys

# 2) Start the stack
make up

# 3) Verify configuration and DB connectivity
make health
```

**DB endpoints**
- Inside containers: `db:5432`
- From host (per compose mapping): `localhost:5433`

---

## First-Time Sanity Check

Run these to confirm everything is wired correctly—only uses Make targets.

```bash
make db-ready-verbose   # show DB env + readiness
make health             # app health check (DB ping)
make db-psql            # list databases inside Postgres
make schema             # apply schema
make etl                # load sample CSVs
make validate           # run validation SQL
make app-psql           # cross-container DB access
```

**Expected outputs**
- DB readiness shows `exit=0`
- Health prints “DB connectivity: OK”
- DB lists include `churn`
- Validate prints row counts, orphaned labels = 0, churn snapshot
- App psql lists churn tables (`customers`, `churn_labels`)

---

## Configuration

Provide DB settings in `.env` (not committed):

```env
POSTGRES_DB=churn
POSTGRES_USER=churn_user
POSTGRES_PASSWORD=churn_pass
```

The app also exposes `DATABASE_URL` inside the container (via compose):

```
postgresql+psycopg://churn_user:churn_pass@db:5432/churn
```

---

## Development Workflow

Most tasks can be run with `make`:

```bash
make up         # build & start all services
make down       # stop
make down-v     # stop + remove volumes (wipe DB data)
make ps         # container status
make logs       # follow logs
make app-sh     # shell into app container
make db-sh      # shell into db container
make db-psql    # psql inside db container
make app-psql   # psql from app container -> db
make db-ready   # check readiness
make health     # run health check
make schema     # apply schema (sql/001_schema.sql)
make etl        # run ETL loader
make validate   # run validation SQL
make e2e        # end-to-end (schema + etl + validate)
make e2e-v      # verbose end-to-end (includes validate-all)
```

**Cleaning / Resetting**
```bash
make clean      # stop containers + wipe volumes (fresh DB)
make reset      # clean + bring db back up
make nuke       # full reset (remove images, data, pycaches)
```

**pre-commit**
```bash
make hooks       # install git hooks
make hooks-run   # run hooks now
make hooks-update
```

---

## Dataset

Telco Customer Churn (Kaggle):
<https://www.kaggle.com/datasets/blastchar/telco-customer-churn>

Columns include churn label, subscribed services, tenure/contract/billing, and demographics.

---

## v0.4.0 — Validation Runbook

End-to-end validation workflow:

```bash
make e2e      # schema + load + validate
make e2e-v    # verbose variant (includes validate-all)
```

**What “good” looks like**
- Non-zero row counts in `customers` and `churn_labels`
- Orphaned labels = 0
- Churn snapshot on latest `label_date` shows true/false split

---

## Roadmap

- ✅ **[0.1.0] Stabilized Baseline** — cleanup, legacy notebook archived, changelog
- ✅ **[0.2.0] Repo Structure** — standardized Python/SQL layout, env templates
- ✅ **[0.3.0] Docker Compose** — Dockerfile + compose (Postgres), health checks, Make targets
- ✅ **[0.4.0] SQL ETL + Validation** — schema creation, CSV ingest CLI, validation runbook
- ⏳ **[0.5.0] Baseline Model** — modeling CLI, artifacts & metrics
- ⏳ **[0.6.0] Tableau Dashboard** — publish dashboard; link from README

See details in [CHANGELOG.md](CHANGELOG.md).

---

## Notebooks Policy

- Notebooks are for **exploration**; production logic lives in `src/`.
- Outputs are stripped automatically (pre-commit `nbstripout`).
- Large or sensitive data should **not** be committed.

---

## Troubleshooting

**Port in use**
If `5433` is busy on the host, change the mapping in `docker-compose.yml`:
```yaml
db:
  ports:
    - "5434:5432"
```

**DB won’t become healthy**
```bash
make clean && make up
```

**Run quick sanity**
```bash
make db-ready
make db-psql
```

---

## License

MIT — see [LICENSE](LICENSE).
