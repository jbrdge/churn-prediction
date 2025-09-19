#!/usr/bin/env python3
"""
Convert the Kaggle Telco CSV into a features parquet for the baseline.

Usage:
  python scripts/archive_to_parquet.py \
    --input data/archive/Telco-Customer-Churn.csv \
    --out data/processed/features.parquet \
    --target churned \
    [--sample 500]
"""
import argparse
import pathlib
import pandas as pd


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--input", required=True)
    ap.add_argument("--out", required=True)
    ap.add_argument("--target", default="churned")
    ap.add_argument("--sample", type=int, default=None)
    args = ap.parse_args()

    src = pathlib.Path(args.input)
    dst = pathlib.Path(args.out)
    dst.parent.mkdir(parents=True, exist_ok=True)

    df = pd.read_csv(src)

    # Map target 'Churn' (Yes/No) -> 1/0 as 'churned'
    if "Churn" not in df.columns:
        raise ValueError("Expected 'Churn' column in archive CSV")
    df[args.target] = (df["Churn"].astype(str).str.strip().str.lower() == "yes").astype(
        int
    )

    # Optional: drop ID-like columns not useful for the baseline
    drop_cols = [c for c in ["customerID", "Churn"] if c in df.columns]
    df = df.drop(columns=drop_cols)

    # basic cleanup: coerce total charges to numeric
    if "TotalCharges" in df.columns:
        df["TotalCharges"] = pd.to_numeric(df["TotalCharges"], errors="coerce")

    # Deterministic sample (pre-split lightweight runs)
    if args.sample:
        df = df.sample(n=min(args.sample, len(df)), random_state=42).reset_index(
            drop=True
        )

    dst.write_bytes(b"")  # ensure path is writable early
    df.to_parquet(dst, index=False)
    print(f"Wrote {len(df)} rows -> {dst}")


if __name__ == "__main__":
    main()
