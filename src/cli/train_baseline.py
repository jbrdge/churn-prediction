#!/usr/bin/env python3
"""
Train a minimal baseline (Logistic Regression) on v0.4.0 features/labels and persist artifacts.

Artifacts saved to --outdir:
- model.pkl
- metrics.json
- params.json
- coefficients.csv (or feature_importances.csv)
- confusion_matrix.png
- roc_curve.png
"""

from __future__ import annotations
import argparse
import json
from pathlib import Path
from typing import Tuple
from typing import Optional

import joblib
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
from sklearn.compose import ColumnTransformer
from sklearn.impute import SimpleImputer
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import (
    accuracy_score,
    precision_score,
    recall_score,
    f1_score,
    roc_auc_score,
    confusion_matrix,
    RocCurveDisplay,
)
from sklearn.model_selection import train_test_split
from sklearn.pipeline import Pipeline
from sklearn.preprocessing import OneHotEncoder


def _build_pipeline(
    numeric_cols: list[str], categorical_cols: list[str], random_state: int
) -> Pipeline:
    numeric_transformer = Pipeline(
        steps=[
            ("imputer", SimpleImputer(strategy="median")),
        ]
    )
    categorical_transformer = Pipeline(
        steps=[
            ("imputer", SimpleImputer(strategy="most_frequent")),
            ("onehot", OneHotEncoder(handle_unknown="ignore", sparse_output=False)),
        ]
    )

    preprocessor = ColumnTransformer(
        transformers=[
            ("num", numeric_transformer, numeric_cols),
            ("cat", categorical_transformer, categorical_cols),
        ],
        remainder="drop",
        verbose_feature_names_out=False,
    )

    clf = LogisticRegression(
        random_state=random_state,
        max_iter=1000,
        solver="liblinear",
    )

    return Pipeline(steps=[("prep", preprocessor), ("clf", clf)])


def _infer_column_types(df: pd.DataFrame, target: str) -> Tuple[list[str], list[str]]:
    X = df.drop(columns=[target])
    numeric_cols = X.select_dtypes(include=[np.number]).columns.tolist()
    categorical_cols = [c for c in X.columns if c not in numeric_cols]
    return numeric_cols, categorical_cols


def _extract_feature_names(fitted_pipe: Pipeline) -> list[str]:
    pre: ColumnTransformer = fitted_pipe.named_steps["prep"]
    try:
        return pre.get_feature_names_out().tolist()
    except Exception:
        # Fallback: minimal names if get_feature_names_out is unavailable
        names = []
        for name, trans, cols in pre.transformers_:
            if hasattr(trans, "get_feature_names_out"):
                try:
                    names.extend(trans.get_feature_names_out(cols).tolist())
                    continue
                except Exception:
                    pass
            # cols may be a list of strings already
            if isinstance(cols, (list, tuple)):
                names.extend(list(cols))
        return names


def _save_confusion_matrix_png(y_true, y_pred, outpath: Path):
    cm = confusion_matrix(y_true, y_pred)
    fig = plt.figure()
    plt.imshow(cm, interpolation="nearest")
    plt.title("Confusion Matrix")
    plt.xlabel("Predicted")
    plt.ylabel("True")
    for (i, j), v in np.ndenumerate(cm):
        plt.text(j, i, str(v), ha="center", va="center")
    plt.tight_layout()
    fig.savefig(outpath)
    plt.close(fig)


def _save_roc_curve_png(y_true, y_proba, outpath: Path):
    # If there's only one class, write a clear placeholder image
    if len(np.unique(y_true)) < 2:
        fig, ax = plt.subplots()
        ax.axis("off")
        ax.text(
            0.5, 0.5, "ROC unavailable (single-class data)", ha="center", va="center"
        )
        fig.savefig(outpath, bbox_inches="tight")
        plt.close(fig)
        return

    fig, ax = plt.subplots()
    RocCurveDisplay.from_predictions(y_true, y_proba, name="LogReg", ax=ax)
    ax.set_title("ROC Curve")
    fig.tight_layout()
    fig.savefig(outpath, bbox_inches="tight")
    plt.close(fig)


def _maybe_sample(
    df: pd.DataFrame, n: Optional[int], random_state: int
) -> pd.DataFrame:
    """
    If n is provided and df has more than n rows, return a deterministic sample of size n.
    Otherwise return df unchanged.
    """
    if n is None:
        return df
    if len(df) <= n:
        return df.reset_index(drop=True)
    return df.sample(n=n, random_state=random_state).reset_index(drop=True)


def train_and_save(
    input_path: str,
    target: str,
    test_size: float,
    random_state: int,
    outdir: str,
    sample_n: Optional[int] = None,
):
    rng = np.random.RandomState(random_state)
    print(f"RNG for this cycle: {rng}")

    df = pd.read_parquet(input_path)
    if target not in df.columns:
        raise ValueError(f"Target column '{target}' not in dataset.")

    # optional sampling (deterministic)
    df = _maybe_sample(df, sample_n, random_state)

    # ensure at least a few rows for split
    min_rows = max(5, int(1 / (1 - test_size)) + 1)
    if len(df) < min_rows:
        raise ValueError(
            f"Dataset too small after sampling: {len(df)} rows. "
            f"Increase --sample or reduce --test-size (current={test_size})."
        )

    numeric_cols, categorical_cols = _infer_column_types(df, target)

    X = df.drop(columns=[target])
    y = df[target].astype(int)  # expect 0/1; cast if bool

    stratify = y if y.nunique() > 1 else None

    X_train, X_test, y_train, y_test = train_test_split(
        X,
        y,
        test_size=test_size,
        random_state=random_state,
        stratify=stratify,
    )

    pipe = _build_pipeline(numeric_cols, categorical_cols, random_state)

    pipe.fit(X_train, y_train)

    # Evaluate
    y_pred = pipe.predict(X_test)
    metrics = {
        "accuracy": float(accuracy_score(y_test, y_pred)),
        "precision": float(precision_score(y_test, y_pred, zero_division=0)),
        "recall": float(recall_score(y_test, y_pred, zero_division=0)),
        "f1": float(f1_score(y_test, y_pred, zero_division=0)),
    }

    # ROC-AUC (need predict_proba)
    if hasattr(pipe.named_steps["clf"], "predict_proba") and y_test.nunique() > 1:
        y_proba = pipe.predict_proba(X_test)[:, 1]
        metrics["roc_auc"] = float(roc_auc_score(y_test, y_proba))
    else:
        y_proba = None
        metrics["roc_auc"] = None

    out = Path(outdir)
    out.mkdir(parents=True, exist_ok=True)

    # Save model
    joblib.dump(pipe, out / "model.pkl")

    # Save metrics & params
    with open(out / "metrics.json", "w") as f:
        json.dump(metrics, f, indent=2)

    params = {
        "model": "LogisticRegression",
        "random_state": int(random_state),
        "test_size": float(test_size),
        "solver": "liblinear",
        "features": {
            "numeric": numeric_cols,
            "categorical": categorical_cols,
        },
        "input_path": input_path,
        "target": target,
    }
    with open(out / "params.json", "w") as f:
        json.dump(params, f, indent=2)

    # Save coefficients as DataFrame (maps to expanded feature names)
    feature_names = _extract_feature_names(pipe)
    coef = pipe.named_steps["clf"].coef_.ravel()
    coef_df = pd.DataFrame({"feature": feature_names, "coefficient": coef})
    coef_df.sort_values("coefficient", key=abs, ascending=False).to_csv(
        out / "coefficients.csv", index=False
    )

    # Plots
    _save_confusion_matrix_png(y_test, y_pred, out / "confusion_matrix.png")
    if y_proba is not None:
        _save_roc_curve_png(y_test, y_proba, out / "roc_curve.png")
    else:
        # Write a placeholder ROC image for determinism
        _save_roc_curve_png(
            y_test, np.zeros_like(y_test, dtype=float), out / "roc_curve.png"
        )


def parse_args():
    p = argparse.ArgumentParser(
        description="Train/evaluate a baseline churn model and persist artifacts."
    )
    p.add_argument(
        "--input",
        required=True,
        help="Path to processed features parquet (includes target column).",
    )
    p.add_argument("--target", required=True, help="Target column name (binary 0/1).")
    p.add_argument(
        "--test-size", type=float, default=0.2, help="Test split size. Default: 0.2"
    )
    p.add_argument(
        "--random-state", type=int, default=42, help="Random seed. Default: 42"
    )
    p.add_argument("--outdir", required=True, help="Output directory for artifacts.")
    p.add_argument(
        "--sample",
        type=int,
        default=None,
        help="Optional row cap for quick tests (e.g., 50).",
    )
    return p.parse_args()


def main():
    args = parse_args()
    train_and_save(
        input_path=args.input,
        target=args.target,
        test_size=args.test_size,
        random_state=args.random_state,
        outdir=args.outdir,
        sample_n=args.sample,
    )


if __name__ == "__main__":
    main()
