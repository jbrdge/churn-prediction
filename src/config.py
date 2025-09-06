"""
Centralized configuration for the churn-prediction app (v0.3.0).

- Loads environment variables from a local `.env` file for dev/compose.
- Does NOT override variables already present in the environment (so CI/prod wins).
- Exposes an immutable Settings object with a convenient SQLAlchemy URL.
"""

from dataclasses import dataclass
import os
from pathlib import Path
from dotenv import load_dotenv

# Load variables from .env if present.
# override=False => existing process env (e.g., CI secrets) take precedence.
load_dotenv(Path(".") / ".env", override=False)


@dataclass(frozen=True)  # frozen => immutable after creation (safer config usage)
class Settings:
    # Postgres connection params (defaults align with docker-compose)
    pg_user: str = os.getenv("POSTGRES_USER", "churn_user")
    pg_password: str = os.getenv("POSTGRES_PASSWORD", "churn_pass")
    pg_host: str = os.getenv(
        "POSTGRES_HOST", "db"
    )  # 'db' is the service name on the compose network
    pg_port: int = int(os.getenv("POSTGRES_PORT", "5432"))
    pg_db: str = os.getenv("POSTGRES_DB", "churn")

    @property
    def sqlalchemy_url(self) -> str:
        """SQLAlchemy DSN using psycopg (v3) driver."""
        return (
            f"postgresql+psycopg://{self.pg_user}:{self.pg_password}"
            f"@{self.pg_host}:{self.pg_port}/{self.pg_db}"
        )


# Single, import-safe config snapshot for the app.
# Keep this module side-effect free beyond reading env at import time.
settings = Settings()

# Optional helper (example):
# def redacted_url(self) -> str:
#     return self.sqlalchemy_url.replace(self.pg_password, "****")
