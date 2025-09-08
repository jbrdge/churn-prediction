"""
CSV → Postgres loader for the churn project.

- Reads .env for DB connection: PGHOST, PGPORT, PGDATABASE, PGUSER, PGPASSWORD
- Loads CSVs from data/raw/: customers.csv, events.csv, churn_labels.csv
- Upserts customers by external_id
- Inserts events/labels referencing customer_id (skips orphans)
- Supports --full-refresh flag to truncate events/labels before reload
"""

import argparse
import csv
import os
from pathlib import Path

import psycopg2
from psycopg2.extras import execute_values
from dotenv import load_dotenv

REQUIRED_FILES = {
    "customers": "customers.csv",
    "events": "events.csv",
    "churn_labels": "churn_labels.csv",
}

CUSTOMERS_COLS = [
    "external_id",
    "created_at",
    "signup_source",
    "country",
    "region",
    "city",
    "plan_tier",
    "is_active",
    "attributes",
]
EVENTS_COLS = ["external_id", "event_type", "event_ts", "properties", "source_file"]
CHURN_COLS = ["external_id", "label", "label_date", "reason_code", "notes"]


def connect_from_env():
    load_dotenv(override=True)
    conn = psycopg2.connect(
        host=os.getenv("PGHOST", "localhost"),
        port=os.getenv("PGPORT", "5432"),
        dbname=os.getenv("PGDATABASE", "postgres"),
        user=os.getenv("PGUSER", "postgres"),
        password=os.getenv("PGPASSWORD", "postgres"),
    )
    conn.autocommit = False
    return conn


def read_csv_rows(path: Path):
    with path.open("r", newline="", encoding="utf-8") as f:
        return list(csv.DictReader(f))


def ensure_columns(rows, required, file):
    if rows and any(col not in rows[0] for col in required):
        missing = [c for c in required if c not in rows[0]]
        raise ValueError(f"{file}: missing required columns {missing}")


def upsert_customers(cur, rows):
    values = []
    for r in rows:
        attrs = r.get("attributes")
        values.append(
            [
                r.get("external_id"),
                r.get("created_at"),
                r.get("signup_source"),
                r.get("country"),
                r.get("region"),
                r.get("city"),
                r.get("plan_tier"),
                r.get("is_active"),
                attrs,
            ]
        )
    sql = """
        INSERT INTO churn.customers (
            external_id, created_at, signup_source, country, region, city, plan_tier,
            is_active, attributes
        ) VALUES %s
        ON CONFLICT (external_id) DO UPDATE SET
            created_at = EXCLUDED.created_at,
            signup_source = EXCLUDED.signup_source,
            country = EXCLUDED.country,
            region = EXCLUDED.region,
            city = EXCLUDED.city,
            plan_tier = EXCLUDED.plan_tier,
            is_active = EXCLUDED.is_active,
            attributes = EXCLUDED.attributes,
            updated_at = NOW();
    """
    execute_values(cur, sql, values, page_size=500)


def map_external_to_uuid(cur):
    cur.execute(
        "SELECT external_id, customer_id FROM churn.customers WHERE external_id IS NOT NULL;"
    )
    return {ext: uuid for ext, uuid in cur.fetchall()}


def load_events(cur, rows, ext2uuid, source_file):
    values = []
    for r in rows:
        cust_uuid = ext2uuid.get(r.get("external_id"))
        if not cust_uuid:
            continue
        values.append(
            [
                cust_uuid,
                r.get("event_type"),
                r.get("event_ts"),
                r.get("properties"),
                source_file,
            ]
        )
    if values:
        sql = """
            INSERT INTO churn.events (customer_id, event_type, event_ts, properties, source_file)
            VALUES %s;
        """
        execute_values(cur, sql, values, page_size=1000)


def load_churn_labels(cur, rows, ext2uuid):
    values = []
    for r in rows:
        cust_uuid = ext2uuid.get(r.get("external_id"))
        if not cust_uuid:
            continue
        values.append(
            [
                cust_uuid,
                r.get("label"),
                r.get("label_date"),
                r.get("reason_code"),
                r.get("notes"),
            ]
        )
    if values:
        sql = """
            INSERT INTO churn.churn_labels (customer_id, label, label_date, reason_code, notes)
            VALUES %s
            ON CONFLICT (customer_id, label_date) DO UPDATE SET
              label = EXCLUDED.label,
              reason_code = EXCLUDED.reason_code,
              notes = EXCLUDED.notes;
        """
        execute_values(cur, sql, values, page_size=500)


def truncate_tables(cur):
    cur.execute("TRUNCATE churn.events RESTART IDENTITY CASCADE;")
    cur.execute("TRUNCATE churn.churn_labels;")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--data-dir", type=str, default="data/raw")
    ap.add_argument("--full-refresh", action="store_true")
    args = ap.parse_args()

    data_dir = Path(args.data_dir)
    files = {k: data_dir / v for k, v in REQUIRED_FILES.items()}
    datasets = {
        name: (read_csv_rows(path) if path.exists() else [])
        for name, path in files.items()
    }

    # Column checks
    if datasets["customers"]:
        ensure_columns(datasets["customers"], CUSTOMERS_COLS, files["customers"].name)
    if datasets["events"]:
        ensure_columns(datasets["events"], EVENTS_COLS, files["events"].name)
    if datasets["churn_labels"]:
        ensure_columns(datasets["churn_labels"], CHURN_COLS, files["churn_labels"].name)

    conn = connect_from_env()
    try:
        with conn.cursor() as cur:
            if args.full_refresh:
                truncate_tables(cur)

            if datasets["customers"]:
                upsert_customers(cur, datasets["customers"])
            ext2uuid = map_external_to_uuid(cur)

            if datasets["events"]:
                load_events(cur, datasets["events"], ext2uuid, str(files["events"]))
            if datasets["churn_labels"]:
                load_churn_labels(cur, datasets["churn_labels"], ext2uuid)

        conn.commit()
        print(
            "Ingest complete. "
            f"{len(datasets['customers'])} customers, "
            f"{len(datasets['events'])} events, "
            f"{len(datasets['churn_labels'])} labels processed."
        )
    except Exception:
        conn.rollback()
        raise
    finally:
        conn.close()


if __name__ == "__main__":
    main()
