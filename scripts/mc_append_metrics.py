#!/usr/bin/env python3
import json
import sys
import csv
import pathlib

if len(sys.argv) != 5:
    print(
        "usage: mc_append_metrics.py <seed> <n> <run_outdir> <csv_path>",
        file=sys.stderr,
    )
    sys.exit(2)

seed = int(sys.argv[1])
n = int(sys.argv[2])
outdir = pathlib.Path(sys.argv[3])
csv_path = pathlib.Path(sys.argv[4])

m_path = outdir / "metrics.json"
if not m_path.exists():
    print("metrics.json missing:", m_path, file=sys.stderr)
    sys.exit(1)
m = json.loads(m_path.read_text())
row = [
    seed,
    n,
    m.get("accuracy"),
    m.get("precision"),
    m.get("recall"),
    m.get("f1"),
    m.get("roc_auc"),
]
csv_path.parent.mkdir(parents=True, exist_ok=True)
with open(csv_path, "a", newline="") as f:
    csv.writer(f).writerow(row)
