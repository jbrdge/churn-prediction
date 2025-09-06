# Customer Churn Prediction

![Version](https://img.shields.io/badge/version-0.3.0-blue.svg)
![Build](https://github.com/jbrdge/churn-prediction/actions/workflows/ci.yml/badge.svg)
![License](https://img.shields.io/badge/license-MIT-green.svg)

End-to-end churn workflow, built incrementally. As of **v0.3.0**, the project ships a **reproducible Docker dev environment** (Python + PostgreSQL) and a simple CLI health check to verify configuration and DB connectivity.

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
- **Docker Compose** to run the full dev stack
- **Makefile** for common tasks (up, down, health, psql, etc.)
- **pre-commit + GitHub Actions** for formatting, linting, and notebook output stripping

---

## Quick Start (Docker, recommended)

```bash
# 1) Clone and configure env
git clone https://github.com/jbrdge/churn-prediction.git
cd churn-prediction
cp .env.example .env   # contains POSTGRES_* keys

# 2) Start the stack
docker compose up -d --build

# 3) Verify configuration and DB connectivity
docker compose exec app python -m src.app health
# or: make health
```

**DB endpoints**
- Inside containers: `db:5432`
- From host (per compose mapping): `localhost:5433`

> The app container stays idle (`sleep infinity`) for interactive use; run one-off commands via `docker compose exec app ...` or `docker compose run --rm app ...`.

---

## First-Time Sanity Check (no host tools required)

Run these to confirm everything is wired correctly—only uses containers.

```bash
# 1) DB readiness (verbose)
docker compose exec -T db sh -lc 'echo "USER=$POSTGRES_USER DB=$POSTGRES_DB"; pg_isready -h 127.0.0.1 -p 5432 -U "$POSTGRES_USER" -d "$POSTGRES_DB"; echo "exit=$?"'

# 2) App health (env + DB ping via SQLAlchemy)
docker compose exec app python -m src.app health

# 3) psql sanity from DB container
docker compose exec -T db sh -lc 'psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "\l"'

# 4) Tiny round-trip (create -> insert -> select -> drop)
docker compose exec -T db sh -lc 'psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "CREATE TABLE sanity(x int); INSERT INTO sanity VALUES (1); SELECT * FROM sanity; DROP TABLE sanity;"'

# 5) Cross-container DB access from app container
docker compose exec -T app sh -lc 'psql -h db -p 5432 -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "\dt"'
```

Expected: readiness shows `exit=0`, health prints `DB connectivity: OK`, `\l` lists databases, and `\dt` likely shows no relations yet.

---

## Configuration

Provide DB settings in `.env` (not committed):

```env
POSTGRES_DB=churn
POSTGRES_USER=churn_user
POSTGRES_PASSWORD=churn_pass
```

The app also exposes `DATABASE_URL` inside the container (via compose), for example:

```
postgresql+psycopg://churn_user:churn_pass@db:5432/churn
```

---

## Development Workflow

Common commands (Makefile shortcuts):

```bash
make up         # build & start containers
make down       # stop
make down-v     # stop + remove volumes (wipe DB data)
make ps         # status
make logs       # tail logs
make app-sh     # shell into app container
make db-sh      # shell into db container
make db-psql    # psql inside db container
make app-psql   # psql from app -> db
make db-ready   # prints "ready" when Postgres is ready
make health     # run CLI health check
make hooks      # install pre-commit git hooks locally
make hooks-run  # run all hooks against the repo now
```

**pre-commit** (runs locally and in CI):
- Black (format), Ruff (lint), nbstripout (strip notebook outputs), plus sanity hooks
- Config: `.pre-commit-config.yaml`
- CI runs the same hooks via `pre-commit/action@v3.0.1`

---

## Dataset

Telco Customer Churn (Kaggle):
<https://www.kaggle.com/datasets/blastchar/telco-customer-churn>

Columns include churn label, subscribed services, tenure/contract/billing, and demographics.
**Note:** The dataset is not required to bring up v0.3.0; ETL/Modeling arrives in v0.4.0–v0.5.0.

---

## Roadmap

- ✅ **[0.1.0] Stabilized Baseline** — cleanup, legacy notebook archived, changelog
- ✅ **[0.2.0] Repo Structure** — standardized Python/SQL layout, env templates
- ✅ **[0.3.0] Docker Compose** — Dockerfile + compose (Postgres), health checks, Make targets
- ⏳ **[0.4.0] SQL ETL** — schema creation + CSV ingest CLI
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
- Ensure `.env` sits next to `docker-compose.yml` and has `POSTGRES_*` keys.
- If you changed credentials after first start, recreate the volume:
```bash
docker compose down -v && docker compose up -d --build
```

**Makefile targets print nothing**
- Make requires **tabs** to start recipe lines. If in doubt, run the commands directly (see sanity steps above).

**Run a quick DB sanity check (Makefile)**
```bash
make db-ready
make db-psql
```

---

## Selected Structure (v0.3.0)

<details>
<summary>Click to expand</summary>

```
.
├── Dockerfile
├── docker-compose.yml
├── .dockerignore
├── .pre-commit-config.yaml
├── requirements.txt
├── requirements-dev.txt
├── Makefile
├── src/
│   ├── app.py
│   └── config.py
└── .github/
    └── workflows/
        └── ci.yml
```

</details>

---

## License

MIT — see [LICENSE](LICENSE).
