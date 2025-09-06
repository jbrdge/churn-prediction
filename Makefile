.PHONY: up down down-v logs ps health app-sh db-sh db-psql app-psql host-psql db-ready db-ready-verbose compose-config check-mysql-refs hooks hooks-run hooks-update commit

# --- Core lifecycle ----------------------------------------------------------

up:            ## Build & start
	docker compose up -d --build

down:          ## Stop
	docker compose down

down-v:        ## Stop + remove volumes (wipes DB data)
	docker compose down -v

logs:          ## Tail all logs
	docker compose logs -f

ps:            ## Container status
	docker compose ps

# --- App / DB interaction ----------------------------------------------------

health:        ## App health (env + DB ping)
	docker compose exec -T app python -m src.app health || true

app-sh:        ## Shell into app container
	docker compose exec app bash

db-sh:         ## Shell into Postgres container
	docker compose exec db sh

db-psql:       ## List databases from inside DB container
	docker compose exec -T db sh -lc 'psql -U "$$POSTGRES_USER" -d "$$POSTGRES_DB" -c "\l"'

app-psql:      ## List relations from app container (proves cross-container DB access)
	docker compose exec -T app sh -lc 'psql -h db -p 5432 -U "$$POSTGRES_USER" -d "$$POSTGRES_DB" -c "\dt"' || true

host-psql:     ## (optional) psql from host -> container (loads .env; requires psql on host)
	( set -a; . ./.env; set +a; psql -h localhost -p 5433 -U "$$POSTGRES_USER" -d "$$POSTGRES_DB" -c '\l' )

# --- Readiness checks --------------------------------------------------------

db-ready:      ## Is Postgres ready? Prints "ready" or fails with "not ready"
	docker compose exec -T db sh -lc '\
		pg_isready -q -h 127.0.0.1 -p 5432 -U "$$POSTGRES_USER" -d "$$POSTGRES_DB" \
		&& echo "ready" || (echo "not ready"; exit 1)'

db-ready-verbose: ## Verbose readiness + env echo inside container
	docker compose exec -T db sh -lc '\
		echo "USER=$$POSTGRES_USER DB=$$POSTGRES_DB HOST=127.0.0.1 PORT=5432"; \
		pg_isready -h 127.0.0.1 -p 5432 -U "$$POSTGRES_USER" -d "$$POSTGRES_DB"; \
		echo "exit=$$?"'

# --- Diagnostics / tooling ---------------------------------------------------

compose-config: ## Show resolved compose (sanity check env)
	docker compose config

check-mysql-refs: ## Find any lingering MySQL refs
	@grep -RInE 'MYSQL|mysql' -- . || echo "No MySQL refs found."

# --- pre-commit helpers ------------------------------------------------------

hooks:         ## Install git hooks for this repo so pre-commit runs on each commit
	command -v pre-commit >/dev/null || python -m pip install --user pre-commit
	pre-commit install

hooks-run:     ## Run all pre-commit hooks against the entire repo
	pre-commit run --all-files

hooks-update:  ## Update pre-commit hook versions to latest safe pins
	pre-commit autoupdate

commit: ## make commit MSG="your message"
	@[ -n "$(MSG)" ] || (echo "Usage: make commit MSG='…'"; exit 1)
	pre-commit run --all-files
	git add -A
	git commit -m "$(MSG)"
