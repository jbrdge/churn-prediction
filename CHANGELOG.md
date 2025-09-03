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
- Roadmap: `ops/repo-structure` → `ops/docker-compose` → `feat/sql-etl` → `feat/model-baseline`

---

# Roadmap

- ✅ **[0.1.0] – Stabilized Baseline**  
  Pre-release baseline with cleanup, legacy notebook archived, and changelog introduced.

- ⏳ **[0.2.0] – Repo Structure**  
  Planned: introduce clear Python/SQL repo layout and env templates.

- ⏳ **[0.3.0] – Docker Compose**  
  Planned: add Dockerfile + docker-compose.yml with health checks and Makefile targets.

- ⏳ **[0.4.0] – SQL ETL**  
  Planned: implement SQL schema + ETL loader.

- ⏳ **[0.5.0] – Baseline Model**  
  Planned: provide baseline churn model CLI, save artifacts and metrics.
