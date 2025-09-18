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
