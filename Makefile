# -------------------------------------------------------------------
# Makefile: docker-first workflow for churn-prediction
# -------------------------------------------------------------------

.DEFAULT_GOAL := help

.PHONY: help \
  up down down-v logs ps \
  build-app build-etl build-all \
  up-db schema etl \
  db-ready db-ready-verbose validate-db validate-churn-table counts validate-all validate \

  sql-check compose-config check-mysql-refs db-logs\

  health app-sh db-sh db-psql app-psql host-psql \
  hooks hooks-run hooks-update commit

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
	docker compose run --rm etl

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
