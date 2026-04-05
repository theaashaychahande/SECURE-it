from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import xgboost as xgb
import os

app = FastAPI(title="SECURE-it Backend API", description="AI scam detection inference service")

# Load model (globally so it mounts once on startup)
model_path = os.path.join(os.path.dirname(__file__), "xgboost_fraud_model.json")
booster = None

# Must match FEATURES order in train_model.py exactly
FEATURES = [
    "amount",
    "is_new_payee",
    "time_of_day_hour",
    "device_trust_score",
    "ip_risk_score",
    "txn_count_1h",
    "txn_count_24h",
    "failed_txn_24h",
    "geo_distance",
    "amount_deviation",
    "is_international",
    "payment_channel_code",
    "merchant_risk_score",
]

@app.on_event("startup")
async def load_model():
    global booster
    if os.path.exists(model_path):
        booster = xgb.Booster()
        booster.load_model(model_path)
        print("XGBoost model loaded successfully.")
    else:
        print(f"Warning: Model file not found at {model_path}. Predictions will fail until trained model is supplied.")

# Full 13-feature payload matching the training schema
class TransactionData(BaseModel):
    amount: float
    is_new_payee: int               # 1 = new recipient, 0 = known
    time_of_day_hour: int           # 0–23
    device_trust_score: float       # 0–100
    ip_risk_score: float = 0.0      # 0–100 (default safe)
    txn_count_1h: int = 1           # transactions in last 1h
    txn_count_24h: int = 1          # transactions in last 24h
    failed_txn_24h: int = 0         # failed transactions in last 24h
    geo_distance: float = 0.0       # km from last transaction
    amount_deviation: float = 0.0   # deviation from user mean spend
    is_international: int = 0       # 1 = cross-border
    payment_channel_code: int = 0   # 0=UPI, 1=Credit Card
    merchant_risk_score: float = 0.0  # 0–100

@app.get("/")
def read_root():
    return {"status": "online", "message": "SECURE-it Backend is running."}

@app.post("/evaluate-risk")
def evaluate_risk(data: TransactionData):
    if booster is None:
        raise HTTPException(status_code=503, detail="Model is currently unavailable. Ensure training is completed.")

    # Build feature vector in exact same order as training
    features = [[
        data.amount,
        data.is_new_payee,
        data.time_of_day_hour,
        data.device_trust_score,
        data.ip_risk_score,
        data.txn_count_1h,
        data.txn_count_24h,
        data.failed_txn_24h,
        data.geo_distance,
        data.amount_deviation,
        data.is_international,
        data.payment_channel_code,
        data.merchant_risk_score,
    ]]

    dmatrix = xgb.DMatrix(features, feature_names=FEATURES)
    prediction = booster.predict(dmatrix)

    risk_probability = float(prediction[0]) * 100

    return {
        "risk_score": round(risk_probability, 2),
        "is_high_risk": risk_probability > 70.0,
        "risk_level": (
            "HIGH" if risk_probability > 70.0
            else "MEDIUM" if risk_probability > 40.0
            else "LOW"
        )
    }
