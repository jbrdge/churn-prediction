#!/usr/bin/env python3
import argparse
import csv
import json
import shutil
import sys
from pathlib import Path


def main():
    ap = argparse.ArgumentParser(
        description="Pick the best Monte-Carlo run by a chosen metric"
    )
    ap.add_argument(
        "--metrics",
        default="artifacts/mc_baseline/metrics.csv",
        help="Path to metrics CSV from monte-carlo runs",
    )
    ap.add_argument(
        "--metric",
        default="roc_auc",
        help="Metric name to rank by (e.g. roc_auc, f1, recall)",
    )
    ap.add_argument(
        "--outdir",
        default="artifacts/mc_baseline/best",
        help="Directory to copy the best run's artifacts into",
    )
    args = ap.parse_args()

    metrics_path = Path(args.metrics)
    if not metrics_path.exists():
        print(f"Error: metrics file not found: {metrics_path}", file=sys.stderr)
        sys.exit(1)

    with open(metrics_path, newline="") as f:
        reader = csv.DictReader(f)
        rows = list(reader)

    if not rows:
        print("Error: no rows in metrics CSV", file=sys.stderr)
        sys.exit(2)
    if args.metric not in rows[0]:
        print(
            f"Error: metric '{args.metric}' not found in CSV headers: {list(rows[0].keys())}",
            file=sys.stderr,
        )
        sys.exit(3)

    # Convert metric to float and pick the row with maximum metric
    def to_float(v):
        try:
            return float(v)
        except Exception:
            return float("-inf")

    best = max(rows, key=lambda row: to_float(row.get(args.metric, "-inf")))

    best_seed = best.get("seed")
    best_n = best.get("n")
    best_val = to_float(best.get(args.metric))

    run_dir = Path(f"artifacts/mc_baseline/run_{best_seed}")
    if not run_dir.exists():
        print(f"Error: best run directory missing: {run_dir}", file=sys.stderr)
        sys.exit(4)

    outdir = Path(args.outdir)
    if outdir.exists():
        shutil.rmtree(outdir)
    shutil.copytree(run_dir, outdir)

    summary = {
        "metric": args.metric,
        "value": best_val,
        "seed": int(best_seed) if best_seed is not None else None,
        "sample_n": int(best_n) if best_n is not None else None,
        "source_run_dir": str(run_dir),
        "copied_to": str(outdir),
    }
    (outdir / "best_summary.json").write_text(json.dumps(summary, indent=2))
    print("Best run summary:")
    print(json.dumps(summary, indent=2))


if __name__ == "__main__":
    main()
