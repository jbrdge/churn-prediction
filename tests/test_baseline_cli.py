import json
import sys
import subprocess
from pathlib import Path

import numpy as np
import pandas as pd


def test_cli_produces_artifacts(tmp_path: Path, monkeypatch):
    # Create tiny synthetic dataset (binary target)
    rng = np.random.RandomState(42)
    n = 60
    df = pd.DataFrame(
        {
            "age": rng.randint(18, 80, size=n),
            "plan": rng.choice(["basic", "pro", "enterprise"], size=n),
            "tenure_months": rng.randint(1, 48, size=n),
            "churned": rng.binomial(1, p=0.3, size=n),
        }
    )
    data_path = tmp_path / "features.parquet"
    df.to_parquet(data_path)

    outdir = tmp_path / "artifacts"
    cmd = [
        sys.executable,
        "-m",
        "src.cli.train_baseline",
        "--input",
        str(data_path),
        "--target",
        "churned",
        "--test-size",
        "0.2",
        "--random-state",
        "123",
        "--outdir",
        str(outdir),
    ]
    completed = subprocess.run(cmd, capture_output=True, text=True)
    assert completed.returncode == 0, completed.stderr

    # Expect files
    expected = [
        "model.pkl",
        "metrics.json",
        "params.json",
        "coefficients.csv",
        "confusion_matrix.png",
        "roc_curve.png",
    ]
    for name in expected:
        assert (outdir / name).exists(), f"missing {name}"

    # Sanity check metrics structure
    metrics = json.loads((outdir / "metrics.json").read_text())
    for key in ["accuracy", "precision", "recall", "f1", "roc_auc"]:
        assert key in metrics
