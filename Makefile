# -------------------------------------------------------------------
# Makefile: docker-first workflow for churn-prediction
# -------------------------------------------------------------------

.DEFAULT_GOAL := help

.PHONY: help \
up down down-v logs ps \
build-app build-etl build-all \
up-db schema etl fix-artifacts-perms\
db-ready db-ready-verbose validate-db validate-churn-table counts validate-all validate \
sql-check compose-config check-mysql-refs db-logs\
health app-sh db-sh db-psql app-psql host-psql \
hooks hooks-run hooks-update commit \
train-baseline test-baseline train-baseline-sample \
monte-carlo monte-carlo-summary mc-best \
show-metrics ls-artifacts

# -------------------------------------------------------------------
# Help
# -------------------------------------------------------------------
help: ## Show this help
	@awk 'BEGIN {FS":.*##"} /^[a-zA-Z0-9_-]+:.*##/ {printf "\033[36m%-26s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

# -------------------------------------------------------------------
# End-to-end: bring up DB, apply schema, run ETL (transform+load), then validations
# -------------------------------------------------------------------
e2e: up-db db-ready schema etl validate
	@echo ">> E2E complete."

e2e-v: up-db db-ready schema etl validate-all
	@echo ">> E2E complete."

# Alias for CI or quick local smoke test
runbook-check: e2e

# Alias for CI or quick local smoke test verbose
runbook-check-verbose: e2e-v

# -------------------------------------------------------------------
# Core lifecycle
# -------------------------------------------------------------------
up: ## Build & start all services
	docker compose up -d --build

down: ## Stop all services
	docker compose down

down-v: ## Stop & remove volumes (wipes DB data)
	docker compose down -v

logs: ## Tail logs
	docker compose logs -f

ps: ## Container status
	docker compose ps

# -------------------------------------------------------------------
# Build targets
# -------------------------------------------------------------------
build-app: ## Build the app image
	docker compose build app

build-etl: ## Build the ETL image
	docker compose build etl

build-all: ## Build all images
	docker compose build

# -------------------------------------------------------------------
# DB / App interaction
# -------------------------------------------------------------------
up-db: ## Start only the Postgres service
	docker compose up -d db

schema: ## Apply schema (sql/001_schema.sql) inside the db container
	docker compose exec -e PGPASSWORD=$$(grep '^POSTGRES_PASSWORD=' .env | cut -d= -f2-) -T db \
		psql -U $$(grep '^POSTGRES_USER=' .env | cut -d= -f2-) \
		     -d $$(grep '^POSTGRES_DB=' .env | cut -d= -f2-) \
		     -f /sql/001_schema.sql

etl: build-etl ## Run ETL loader (CSV -> Postgres)
	docker compose run --rm etl \
	-e MPLBACKEND=Agg -e MPLCONFIGDIR=/tmp/matplotlib -e XDG_CACHE_HOME=/tmp

health: ## App health (env + DB ping)
	docker compose exec -T app python -m src.app health || true

app-sh: ## Shell into app container
	docker compose exec app bash

db-sh: ## Shell into Postgres container
	docker compose exec db sh

db-psql: ## List databases from inside DB container
	docker compose exec -T db sh -lc 'psql -U "$$POSTGRES_USER" -d "$$POSTGRES_DB" -c "\l"'

app-psql: ## List relations from app (proves cross-container DB access)
	docker compose exec -T app sh -lc 'psql -h db -p 5432 -U "$$POSTGRES_USER" -d "$$POSTGRES_DB" -c "\dt"' || true

host-psql: ## (optional) psql from host -> container (requires host psql)
	( set -a; . ./.env; set +a; psql -h localhost -p $${POSTGRES_PORT:-5432} -U "$$POSTGRES_USER" -d "$$POSTGRES_DB" -c '\l' )

fix-artifacts-perms:
	@[ -n "$$HOST_UID" ] || (echo "Set HOST_UID/HOST_GID (source scripts/docker-env.sh)"; exit 1)
	docker compose run --rm --entrypoint sh etl -c 'chown -R $$HOST_UID:$$HOST_GID artifacts || true' \
	-e MPLBACKEND=Agg -e MPLCONFIGDIR=/tmp/matplotlib -e XDG_CACHE_HOME=/tmp

# -------------------------------------------------------------------
# Readiness & validation
# -------------------------------------------------------------------
db-ready: ## Wait until Postgres accepts connections (30s timeout)
	docker compose exec -T db sh -lc '\
	for i in $$(seq 1 30); do \
	  pg_isready -q -h 127.0.0.1 -p 5432 -U "$$POSTGRES_USER" -d "$$POSTGRES_DB" \
	    && echo "ready" && exit 0; \
	  echo "waiting ($$i/30) ..."; sleep 1; \
	done; \
	echo "not ready"; exit 1'

db-ready-verbose: ## Verbose readiness with retries + env echo
	docker compose exec -T db sh -lc '\
		echo "USER=$$POSTGRES_USER DB=$$POSTGRES_DB HOST=127.0.0.1 PORT=5432"; \
		for i in $$(seq 1 30); do \
		  pg_isready -h 127.0.0.1 -p 5432 -U "$$POSTGRES_USER" -d "$$POSTGRES_DB" && break; \
		  echo "waiting ($$i/30) ..."; sleep 1; \
		done; \
		pg_isready -h 127.0.0.1 -p 5432 -U "$$POSTGRES_USER" -d "$$POSTGRES_DB"; \
		echo "exit=$$?"'

validate-db: ## List schemas (should include 'churn')
	docker compose exec -T db sh -lc 'psql -h 127.0.0.1 -p 5432 -U "$$POSTGRES_USER" -d "$$POSTGRES_DB" -c "\dn"'

validate-churn-table: ## List churn.* tables
	docker compose exec -T db sh -lc 'psql -h 127.0.0.1 -p 5432 -U "$$POSTGRES_USER" -d "$$POSTGRES_DB" -c "\dt churn.*"'


counts: ## Row counts across churn tables
	docker compose exec -T db sh -lc 'psql -h 127.0.0.1 -p 5432 -U "$$POSTGRES_USER" -d "$$POSTGRES_DB" -c "SELECT '\''customers'\'' AS t, COUNT(*) AS n FROM churn.customers UNION ALL SELECT '\''churn_labels'\'', COUNT(*) FROM churn.churn_labels;"'

validate-all: db-ready validate-db validate-churn-table counts ## Run all DB validations

validate: ## Run sql/010_validation.sql if present
	@if [ -f sql/010_validation.sql ]; then \
		docker compose exec -e PGPASSWORD=$$(grep '^POSTGRES_PASSWORD=' .env | cut -d= -f2-) -T db \
			psql -U $$(grep '^POSTGRES_USER=' .env | cut -d= -f2-) \
			     -d $$(grep '^POSTGRES_DB=' .env | cut -d= -f2-) \
			     -f /sql/010_validation.sql ; \
	else \
		echo "sql/010_validation.sql not found (Issue 4) — skipping."; \
	fi

# -------------------------------------------------------------------
# Diagnostics / tooling
# -------------------------------------------------------------------
sql-check: ## Verify sql/ is mounted into db container
	docker compose exec db ls -la /sql


compose-config: ## Show resolved compose (env + mounts)
	docker compose config

check-mysql-refs: ## Find any lingering MySQL refs
	@grep -RInE 'MYSQL|mysql' -- . || echo "No MySQL refs found."

db-logs: ## Tail Postgres logs
	docker compose logs -f db

# -------------------------------------------------------------------
# pre-commit helpers
# -------------------------------------------------------------------
hooks: ## Install git hooks so pre-commit runs on commit
	command -v pre-commit >/dev/null || python -m pip install --user pre-commit
	pre-commit install

hooks-run: ## Run all pre-commit hooks across repo
	pre-commit run --all-files

hooks-update: ## Update pre-commit hook versions
	pre-commit autoupdate

commit: ## make commit MSG="your message"
	@[ -n "$(MSG)" ] || (echo "Usage: make commit MSG='…'"; exit 1)
	pre-commit run --all-files
	git add -A
	git commit -m "$(MSG)"


# -------------------------------------------------------------------
# clean helpers
# -------------------------------------------------------------------
# Stop everything and wipe DB volume (fresh DB next up)
clean: ## Stop & remove containers + volumes (fresh DB)
	docker compose down -v

# Hard reset: clean + remove images, dangling data, and processed CSVs (optional)
nuke: ## Full reset (includes images and processed data)
	docker compose down -v --rmi local --remove-orphans
	rm -rf data/processed || true
	find . -name "__pycache__" -type d -prune -exec rm -rf {} \; || true

# Convenience: full reset + rebuild db only
reset: clean
	docker compose up -d db



# -------------------------------------------------------------------
# training tools
# -------------------------------------------------------------------

# Build features.parquet from the Kaggle archive (no DB dependency)
# usage: make make-features-from-archive [N=500]
# if no N, it will transfer full dataset to parquet
make-features-from-archive:
	 docker compose run --rm --entrypoint sh etl \
	 	-c 'python scripts/archive_to_parquet.py \
	 		--input data/archive/Telco-Customer-Churn.csv \
	 		--out data/processed/features.parquet \
	 		--target churned \
	 		$${N:+--sample $${N}}'

# Train (full dataset parquet)
train-baseline:
	 docker compose run --rm -e MPLBACKEND=Agg --entrypoint sh etl \
	 	-c 'python -m src.cli.train_baseline \
	 		--input data/processed/features.parquet \
	 		--target churned \
	 		--test-size 0.2 \
	 		--random-state 42 \
	 		--outdir artifacts/baseline_v1 && echo ">> baseline artifacts at artifacts/baseline_v1"'

# Pytest for the baseline CLI
test-baseline:
	 docker compose run --rm -e MPLBACKEND=Agg --entrypoint sh etl \
	 	-c 'pytest -q tests/test_baseline_cli.py'

# Sampled run: make train-baseline-sample N=50
train-baseline-sample:
	 docker compose run --rm -e MPLBACKEND=Agg --entrypoint sh etl \
	 	-c 'python -m src.cli.train_baseline \
	 		--input data/processed/features.parquet \
	 		--target churned \
	 		--test-size 0.2 \
	 		--random-state 42 \
	 		--sample $(N) \
	 		--outdir artifacts/baseline_v1_sample_$(N)'

# Monte-Carlo runner (no heredocs)
N ?= 100
MC_ITERS ?= 20
OUTBASE ?= artifacts/mc_baseline
INPUT ?= data/processed/features.parquet
TARGET ?= churned

monte-carlo:
	docker compose run --rm \
	--entrypoint sh etl -c 'rm -rf $(OUTBASE) && mkdir -p $(OUTBASE) && echo "seed,n,accuracy,precision,recall,f1,roc_auc" > $(OUTBASE)/metrics.csv'
	@for i in $$(seq 1 $(MC_ITERS)); do \
	  OUTDIR=$(OUTBASE)/run_$$i; \
	  echo ">> run seed=$$i N=$(N) -> $$OUTDIR"; \
	  docker compose run --rm -e MPLBACKEND=Agg --entrypoint sh etl \
	    -c 'python -m src.cli.train_baseline --input $(INPUT) --target $(TARGET) --test-size 0.2 --random-state '$$i' --sample $(N) --outdir '$$OUTDIR; \
	  docker compose run --rm --entrypoint sh etl \
	    -c 'python scripts/mc_append_metrics.py '$$i' $(N) '$$OUTDIR' $(OUTBASE)/metrics.csv'; \
	done
	@echo ">> Monte-Carlo complete: $(OUTBASE)/metrics.csv"

# Summary using pandas (no heredocs)
monte-carlo-summary:
	 docker compose run --rm --entrypoint sh etl \
	 	-c 'python -c "import pandas as pd; import sys; df=pd.read_csv(\"$(OUTBASE)/metrics.csv\"); print(df.describe()[[\"accuracy\",\"precision\",\"recall\",\"f1\",\"roc_auc\"]])"'

# identifies best run
mc-best:
	docker compose run --rm --entrypoint sh etl -c 'python scripts/mc_best.py --metric $${METRIC:-roc_auc}'

# Pretty-print best_summary.json (created by `make mc-best`)
mc-show-best:
	docker compose run --rm --entrypoint sh etl -c '\
p=artifacts/mc_baseline/best/best_summary.json; \
if [ -f "$$p" ]; then cat "$$p" | python -m json.tool; \
else echo "best_summary.json not found. Run: make mc-best"; exit 1; fi'

# Pretty-print metrics.json from the best run
mc-show-best-metrics:
	docker compose run --rm --entrypoint sh etl -c '\
p=artifacts/mc_baseline/best/metrics.json; \
if [ -f "$$p" ]; then cat "$$p" | python -m json.tool; \
else echo "best metrics not found. Run: make mc-best"; exit 1; fi'

# List artifacts in the best run folder
mc-ls-best:
	docker compose run --rm --entrypoint sh etl -c 'ls -la artifacts/mc_baseline/best'

# -------------------------------------------------------------------
# artifact checks
# -------------------------------------------------------------------

# Show metrics.json nicely
# override default entrypoint/cmd and run our script
show-metrics:
	docker compose run --rm --entrypoint sh etl -c 'python scripts/show_metrics.py' \
	-e MPLBACKEND=Agg -e MPLCONFIGDIR=/tmp/matplotlib -e XDG_CACHE_HOME=/tmp

# List baseline artifacts
ls-artifacts:
	docker compose run --rm --entrypoint sh etl -c 'ls -la artifacts/baseline_v1' \
	-e MPLBACKEND=Agg -e MPLCONFIGDIR=/tmp/matplotlib -e XDG_CACHE_HOME=/tmp
