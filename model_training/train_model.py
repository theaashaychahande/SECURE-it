"""
SECURE-it Fraud Detection Model Trainer
========================================
Trains an XGBoost binary classifier on two real datasets:
  1. UPI Fraud      : dataset/UPI fraud/transactions_train.csv
  2. Credit Card    : dataset/Credit card fraud/creditcard_2023.csv

Both datasets are normalised to a shared feature schema and merged before
training so the final model handles both payment channel types.

Output: ../secure_it_backend/xgboost_fraud_model.json
"""

import os
import numpy as np
import pandas as pd
import xgboost as xgb
from sklearn.model_selection import train_test_split
from sklearn.metrics import (
    accuracy_score, precision_score, recall_score,
    f1_score, roc_auc_score, classification_report
)
from sklearn.preprocessing import LabelEncoder

# ── Paths ──────────────────────────────────────────────────────────────────────
BASE_DIR         = os.path.dirname(os.path.abspath(__file__))
UPI_TRAIN_PATH   = os.path.join(BASE_DIR, "dataset", "UPI fraud",      "transactions_train.csv")
UPI_TEST_PATH    = os.path.join(BASE_DIR, "dataset", "UPI fraud",      "transactions_test.csv")
CC_PATH          = os.path.join(BASE_DIR, "dataset", "Credit card fraud", "creditcard_2023.csv")
MODEL_OUT        = os.path.join(BASE_DIR, "..", "secure_it_backend",   "xgboost_fraud_model.json")

# Shared feature schema (columns that will be present in both datasets after mapping)
FEATURES = [
    "amount",               # transaction amount
    "is_new_payee",         # 1 if new recipient, 0 otherwise
    "time_of_day_hour",     # 0-23
    "device_trust_score",   # 0-100 composite score
    "ip_risk_score",        # 0-100
    "txn_count_1h",         # transaction count in last 1h
    "txn_count_24h",        # transaction count in last 24h
    "failed_txn_24h",       # failed transactions in last 24h
    "geo_distance",         # km from last transaction
    "amount_deviation",     # deviation from user mean spend
    "is_international",     # 1 = cross-border
    "payment_channel_code", # 0=UPI, 1=CC (one-hot could be added later)
    "merchant_risk_score",  # 0-100
]
TARGET = "is_fraud"


# ── UPI Dataset ────────────────────────────────────────────────────────────────
def load_upi() -> pd.DataFrame:
    print("\n[UPI] Loading training data …")
    train = pd.read_csv(UPI_TRAIN_PATH)

    # Optional test split exists → merge for maximum training data
    if os.path.exists(UPI_TEST_PATH):
        print("[UPI] Found transactions_test.csv — merging for more signal …")
        test = pd.read_csv(UPI_TEST_PATH)
        # test may or may not have is_fraud; keep only rows that do
        if TARGET in test.columns:
            train = pd.concat([train, test], ignore_index=True)
        else:
            print("[UPI] test CSV has no is_fraud column — skipping merge.")

    print(f"[UPI] Rows: {len(train):,} | Fraud rate: {train[TARGET].mean()*100:.2f}%")

    # ── Encode categorical columns ──
    # payment_channel: UPI/NEFT/RTGS/… → int
    le = LabelEncoder()
    if "payment_channel" in train.columns:
        train["payment_channel_code"] = le.fit_transform(train["payment_channel"].astype(str))
    else:
        train["payment_channel_code"] = 0

    # device_type → trust score heuristic if numeric col absent
    device_trust_map = {"mobile": 75, "desktop": 60, "tablet": 50}
    if "device_type" in train.columns:
        train["device_trust_score"] = (
            train["device_type"].str.lower()
                .map(device_trust_map)
                .fillna(50)
        )
    else:
        train["device_trust_score"] = 50

    # Rename / map to shared schema
    rename = {
        "transaction_amount":          "amount",
        "geo_distance_from_last_txn":  "geo_distance",
        "amount_deviation_from_user_mean": "amount_deviation",
        "failed_txn_count_24h":        "failed_txn_24h",
        "merchant_risk_score":         "merchant_risk_score",
        "ip_risk_score":               "ip_risk_score",
        "txn_count_1h":                "txn_count_1h",
        "txn_count_24h":               "txn_count_24h",
        "is_international":            "is_international",
    }
    train.rename(columns={k: v for k, v in rename.items() if k in train.columns}, inplace=True)

    # is_new_payee not in UPI set → approximate: geo_distance > 500 & new merchant
    if "is_new_payee" not in train.columns:
        train["is_new_payee"] = ((train.get("geo_distance", pd.Series(0)) > 500)).astype(int)

    # time_of_day_hour from transaction_time
    if "time_of_day_hour" not in train.columns and "transaction_time" in train.columns:
        train["time_of_day_hour"] = pd.to_datetime(
            train["transaction_time"], errors="coerce"
        ).dt.hour.fillna(12).astype(int)

    # Fill anything still missing
    for col in FEATURES:
        if col not in train.columns:
            train[col] = 0

    return train[FEATURES + [TARGET]]


# ── Credit Card Dataset ────────────────────────────────────────────────────────
def load_credit_card() -> pd.DataFrame:
    print("\n[CC]  Loading creditcard_2023.csv (≈310 MB) … please wait …")
    df = pd.read_csv(CC_PATH)
    print(f"[CC]  Rows: {len(df):,} | Fraud rate: {df['Class'].mean()*100:.2f}%")

    # Rename target
    df.rename(columns={"Class": TARGET, "Amount": "amount"}, inplace=True)

    # V1–V28 are PCA-transformed anonymised features; we use Amount + derived cols.
    # Map to shared schema as best we can:
    df["is_new_payee"]         = 0          # not available in CC data
    df["time_of_day_hour"]     = 12         # Time col is seconds-elapsed, not hour
    df["device_trust_score"]   = 70         # not available
    df["ip_risk_score"]        = df.get("V14", pd.Series(0)).abs().clip(0, 100)  # V14 correlates with fraud
    df["txn_count_1h"]         = 1
    df["txn_count_24h"]        = 1
    df["failed_txn_24h"]       = 0
    df["geo_distance"]         = 0
    df["amount_deviation"]     = df["amount"] - df["amount"].mean()
    df["is_international"]     = 0
    df["payment_channel_code"] = 1          # 1 = Credit Card
    df["merchant_risk_score"]  = df.get("V17", pd.Series(0)).abs().clip(0, 100)

    return df[FEATURES + [TARGET]]


# ── Training ───────────────────────────────────────────────────────────────────
def train():
    # Load both datasets
    upi_df = load_upi()
    cc_df  = load_credit_card()

    print(f"\n[MERGE] UPI rows : {len(upi_df):,} | CC rows: {len(cc_df):,}")
    combined = pd.concat([upi_df, cc_df], ignore_index=True)
    combined.fillna(0, inplace=True)

    print(f"[MERGE] Total rows    : {len(combined):,}")
    print(f"[MERGE] Overall fraud : {combined[TARGET].mean()*100:.2f}%")

    X = combined[FEATURES]
    y = combined[TARGET]

    X_train, X_test, y_train, y_test = train_test_split(
        X, y, test_size=0.2, random_state=42, stratify=y
    )

    # Class imbalance ratio for scale_pos_weight
    neg = (y_train == 0).sum()
    pos = (y_train == 1).sum()
    spw = round(neg / pos, 2)
    print(f"\n[TRAIN] scale_pos_weight = {spw}  (neg={neg:,}  pos={pos:,})")

    print("[TRAIN] Fitting XGBoost …")
    model = xgb.XGBClassifier(
        n_estimators=300,
        max_depth=6,
        learning_rate=0.05,
        subsample=0.8,
        colsample_bytree=0.8,
        scale_pos_weight=spw,        # handle class imbalance
        eval_metric="logloss",
        random_state=42,
        n_jobs=-1,                   # use all CPU cores
    )

    model.fit(
        X_train, y_train,
        eval_set=[(X_test, y_test)],
        verbose=50,
    )

    # ── Evaluation ──
    print("\n[EVAL] Evaluating on held-out test set …")
    y_pred      = model.predict(X_test)
    y_pred_prob = model.predict_proba(X_test)[:, 1]

    print(f"  Accuracy  : {accuracy_score(y_test, y_pred)*100:.2f}%")
    print(f"  Precision : {precision_score(y_test, y_pred, zero_division=0)*100:.2f}%")
    print(f"  Recall    : {recall_score(y_test, y_pred, zero_division=0)*100:.2f}%")
    print(f"  F1-Score  : {f1_score(y_test, y_pred, zero_division=0)*100:.2f}%")
    print(f"  ROC-AUC   : {roc_auc_score(y_test, y_pred_prob)*100:.2f}%")
    print("\nClassification Report:\n", classification_report(y_test, y_pred))

    # ── Feature importance ──
    print("[INFO] Top feature importances:")
    fi = sorted(zip(FEATURES, model.feature_importances_), key=lambda x: x[1], reverse=True)
    for feat, score in fi:
        bar = "█" * int(score * 300)
        print(f"  {feat:<30} {score:.4f}  {bar}")

    # ── Save ──
    os.makedirs(os.path.dirname(MODEL_OUT), exist_ok=True)
    model.save_model(MODEL_OUT)
    print(f"\n✅  Model saved → {os.path.abspath(MODEL_OUT)}")
    print("Training complete!")


if __name__ == "__main__":
    train()
