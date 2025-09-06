"""
CLI entrypoint for churn-prediction (v0.3.0).

Currently exposes a single `health` subcommand that:
- prints a redacted SQLAlchemy URL (to verify env wiring),
- opens a DB connection, and
- runs a trivial query to confirm connectivity.

Designed to stay small and import-safe; add more subcommands in later milestones
(e.g., `schema apply`, `ingest`, `model train`).
"""

# Standard libs
import argparse
import sys

# Third-party
from sqlalchemy import create_engine, text

# Local config (immutable settings snapshot)
from src.config import settings


def cmd_health(_):
    """
    Verify configuration and DB connectivity.
    Returns 0 on success, 1 on failure (so CI/Make can use exit code).
    """
    print("[health] settings OK")
    # Redact password before printing DSN to logs
    print(
        f"[health] sqlalchemy_url: {settings.sqlalchemy_url.replace(settings.pg_password, '****')}"
    )
    try:
        # pool_pre_ping=True -> proactively checks connections; avoids stale-conn errors
        engine = create_engine(settings.sqlalchemy_url, pool_pre_ping=True)
        with engine.connect() as conn:
            # Minimal roundtrip to ensure the DB is actually reachable
            conn.execute(text("SELECT 1"))
        print("[health] DB connectivity: OK")
        return 0
    except Exception as e:
        # Keep this broad for a simple health signal; detailed errors show up in logs
        print(f"[health] DB connectivity: FAIL -> {e}")
        return 1


def main():
    """Argument parser scaffold; easy to extend with new subcommands later."""
    p = argparse.ArgumentParser(
        prog="churn-app", description="CLI for churn-prediction project"
    )
    sub = p.add_subparsers(dest="command", required=True)

    # `health` subcommand
    h = sub.add_parser("health", help="Check env + DB connectivity")
    h.set_defaults(func=cmd_health)

    args = p.parse_args()
    # Call the selected subcommand and exit with its return code
    sys.exit(args.func(args))


if __name__ == "__main__":
    # Allow: `python -m src.app health`
    main()
