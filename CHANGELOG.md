# Changelog
All notable changes to this project are documented here.
Format follows https://keepachangelog.com and uses Semantic Versioning.

## [0.1.0] - 2025-09-02 (Pre-release)
### Added
- Initial stabilized baseline of the project
- Archived legacy notebook under `notebooks/legacy/` (deprecated but runnable)

### Removed
- Deleted `sql/02_sanity_checks_and_baseline.sql` (legacy, no longer needed)

### Fixed
- Broken import/path issue
- Stray inline reviewer comment
- Env/file reference alignment

### Notes
- Pre-release baseline before code-first + Docker restructure
- Next: `ops/repo-structure` → `ops/docker-compose` → `feat/sql-etl` → `feat/model-baseline`
