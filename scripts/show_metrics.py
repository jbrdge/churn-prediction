#!/usr/bin/env python3
import json
import pathlib
import sys

p = pathlib.Path("artifacts/baseline_v1/metrics.json")
if not p.exists():
    print("metrics.json not found at", p, file=sys.stderr)
    sys.exit(1)
print(json.dumps(json.loads(p.read_text()), indent=2))
