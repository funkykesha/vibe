from pathlib import Path
from contextlib import asynccontextmanager
from datetime import datetime, timezone
import json

from fastapi import Depends, FastAPI, Header, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse
from fastapi.staticfiles import StaticFiles
from sqlalchemy.orm import Session

from . import models, schemas
from .config import settings
from .db import Base, engine, get_db
from .seed import seed_defaults


@asynccontextmanager
async def lifespan(app: FastAPI):
    Base.metadata.create_all(bind=engine)
    with Session(engine) as db:
        seed_defaults(db)
    yield


app = FastAPI(title=settings.app_name, lifespan=lifespan)

SALARY_EVENT_TYPES = {"5th_payday", "20th_payday", "vacation", "bonus", "other"}


app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins,
    allow_credentials=True,
    allow_methods=["GET", "POST", "PATCH"],
    allow_headers=["*"],
)


def require_access(authorization: str | None = Header(default=None)) -> None:
    if settings.is_local:
        return
    expected = f"Bearer {settings.access_token}"
    if authorization != expected:
        raise HTTPException(status_code=403, detail="Access denied")


@app.get("/api/accounts", response_model=list[schemas.AccountOut], dependencies=[Depends(require_access)])
def get_accounts(db: Session = Depends(get_db)):
    return db.query(models.Account).order_by(models.Account.id.asc()).all()


@app.patch("/api/accounts/{account_id}", response_model=schemas.AccountOut, dependencies=[Depends(require_access)])
def patch_account(account_id: int, patch: schemas.AccountPatch, db: Session = Depends(get_db)):
    account = db.get(models.Account, account_id)
    if account is None:
        raise HTTPException(status_code=404, detail="Account not found")

    if patch.val is not None:
        account.val = patch.val
    if patch.currency is not None:
        account.currency = patch.currency

    db.commit()
    db.refresh(account)
    return account


@app.get("/api/settings", response_model=schemas.SettingsOut, dependencies=[Depends(require_access)])
def get_settings(db: Session = Depends(get_db)):
    categories = db.query(models.Category).order_by(models.Category.id.asc()).all()
    deductions = db.query(models.Deduction).order_by(models.Deduction.id.asc()).all()
    app_settings = db.get(models.AppSettings, 1)
    if app_settings is None:
        raise HTTPException(status_code=500, detail="Settings not initialized")

    return schemas.SettingsOut(
        categories=categories,
        deductions=deductions,
        usdRate=app_settings.usd_rate,
        mortgage=app_settings.mortgage,
    )


@app.patch("/api/settings", response_model=schemas.SettingsOut, dependencies=[Depends(require_access)])
def patch_settings(patch: schemas.SettingsPatch, db: Session = Depends(get_db)):
    if patch.categories is not None:
        for item in patch.categories:
            row = db.get(models.Category, item.id)
            if row is None:
                db.add(models.Category(id=item.id, name=item.name, pct=item.pct))
            else:
                row.name = item.name
                row.pct = item.pct

    if patch.deductions is not None:
        for item in patch.deductions:
            row = db.get(models.Deduction, item.id)
            if row is None:
                db.add(models.Deduction(id=item.id, name=item.name, val=item.val))
            else:
                row.name = item.name
                row.val = item.val

    app_settings = db.get(models.AppSettings, 1)
    if app_settings is None:
        app_settings = models.AppSettings(id=1)
        db.add(app_settings)

    if patch.usdRate is not None:
        app_settings.usd_rate = patch.usdRate
    if patch.mortgage is not None:
        app_settings.mortgage = patch.mortgage

    db.commit()
    return get_settings(db)


def _parse_num(value: str) -> float:
    cleaned = (value or "").replace(" ", "").replace(",", ".")
    try:
        return float(cleaned)
    except Exception:
        return 0.0


def _snapshot_out(row: models.Snapshot) -> schemas.SnapshotOut:
    return schemas.SnapshotOut(
        id=row.id,
        label=row.label,
        timestamp=row.timestamp,
        payloadVersion=row.payload_version,
        mortgage=row.mortgage,
        usdRate=row.usd_rate,
        accounts=json.loads(row.accounts_json),
        categories=json.loads(row.categories_json),
        currencies=json.loads(row.currencies_json),
        totals=json.loads(row.totals_json),
    )


@app.post("/api/salary-events", response_model=schemas.SalaryEventOut, dependencies=[Depends(require_access)])
def create_salary_event(payload: schemas.SalaryEventIn, db: Session = Depends(get_db)):
    if payload.eventType not in SALARY_EVENT_TYPES:
        raise HTTPException(status_code=400, detail="Unsupported event type")
    now = datetime.now(timezone.utc).isoformat()
    row = models.SalaryEvent(
        event_date=payload.eventDate,
        event_type=payload.eventType,
        gross=payload.gross,
        deductions=payload.deductions,
        net=payload.net,
        distribution_json=json.dumps(payload.distribution, ensure_ascii=False),
        created_at=now,
    )
    db.add(row)
    db.commit()
    db.refresh(row)
    return schemas.SalaryEventOut(
        id=row.id,
        eventDate=row.event_date,
        eventType=row.event_type,
        gross=row.gross,
        deductions=row.deductions,
        net=row.net,
        distribution=json.loads(row.distribution_json),
        createdAt=row.created_at,
    )


@app.get("/api/salary-events", response_model=list[schemas.SalaryEventOut], dependencies=[Depends(require_access)])
def list_salary_events(db: Session = Depends(get_db)):
    rows = db.query(models.SalaryEvent).order_by(models.SalaryEvent.id.desc()).all()
    return [
        schemas.SalaryEventOut(
            id=row.id,
            eventDate=row.event_date,
            eventType=row.event_type,
            gross=row.gross,
            deductions=row.deductions,
            net=row.net,
            distribution=json.loads(row.distribution_json),
            createdAt=row.created_at,
        )
        for row in rows
    ]


@app.post("/api/snapshots", response_model=schemas.SnapshotOut, dependencies=[Depends(require_access)])
def create_snapshot(payload: schemas.SnapshotCreateIn, db: Session = Depends(get_db)):
    accounts = db.query(models.Account).order_by(models.Account.id.asc()).all()
    categories = db.query(models.Category).order_by(models.Category.id.asc()).all()
    app_settings = db.get(models.AppSettings, 1)
    if app_settings is None:
        raise HTTPException(status_code=500, detail="Settings not initialized")

    usd_rate = _parse_num(app_settings.usd_rate)
    mortgage_num = _parse_num(app_settings.mortgage)
    account_rows = []
    category_totals = {}
    non_debt = 0.0
    full_capital = 0.0
    rub_total = 0.0
    usd_total = 0.0
    for a in accounts:
        raw = _parse_num(a.val)
        adjusted = raw * usd_rate if a.currency == "USD" else raw
        account_rows.append({
            "id": a.id, "bank": a.bank, "name": a.name, "type": a.type, "cat": a.cat,
            "val": a.val, "currency": a.currency, "raw": raw, "adjustedRub": adjusted,
        })
        category_totals[a.cat] = category_totals.get(a.cat, 0.0) + adjusted
        full_capital += adjusted
        if a.type != "Долг":
            non_debt += adjusted
        if a.currency == "USD":
            usd_total += raw
        else:
            rub_total += raw

    totals = {
        "fullCapital": full_capital,
        "capitalExcludingDebts": non_debt,
        "categoryTotals": category_totals,
        "currencyAdjustedTotals": {"rubRaw": rub_total, "usdRaw": usd_total, "usdRate": usd_rate},
        "mortgageAdjustedPosition": full_capital - mortgage_num,
    }
    timestamp = datetime.now(timezone.utc).isoformat()
    row = models.Snapshot(
        label=(payload.label or f"Snapshot {timestamp[:19]}"),
        timestamp=timestamp,
        payload_version="v1",
        accounts_json=json.dumps(account_rows, ensure_ascii=False),
        categories_json=json.dumps([{"id": c.id, "name": c.name, "pct": c.pct} for c in categories], ensure_ascii=False),
        currencies_json=json.dumps({"USD": usd_rate, "base": "RUB"}, ensure_ascii=False),
        totals_json=json.dumps(totals, ensure_ascii=False),
        mortgage=app_settings.mortgage,
        usd_rate=app_settings.usd_rate,
    )
    db.add(row)
    db.commit()
    db.refresh(row)
    return _snapshot_out(row)


@app.get("/api/snapshots", response_model=list[schemas.SnapshotOut], dependencies=[Depends(require_access)])
def list_snapshots(db: Session = Depends(get_db)):
    rows = db.query(models.Snapshot).order_by(models.Snapshot.id.desc()).all()
    return [_snapshot_out(row) for row in rows]


@app.get("/api/snapshots/compare", response_model=schemas.SnapshotCompareOut, dependencies=[Depends(require_access)])
def compare_snapshots(left_id: int, right_id: int, db: Session = Depends(get_db)):
    left = db.get(models.Snapshot, left_id)
    right = db.get(models.Snapshot, right_id)
    if left is None or right is None:
        raise HTTPException(status_code=404, detail="Snapshot not found")
    left_out = _snapshot_out(left)
    right_out = _snapshot_out(right)
    left_totals = left_out.totals
    right_totals = right_out.totals
    delta = {
        "fullCapital": right_totals.get("fullCapital", 0) - left_totals.get("fullCapital", 0),
        "capitalExcludingDebts": right_totals.get("capitalExcludingDebts", 0) - left_totals.get("capitalExcludingDebts", 0),
        "mortgageAdjustedPosition": right_totals.get("mortgageAdjustedPosition", 0) - left_totals.get("mortgageAdjustedPosition", 0),
        "categoryTotals": {},
    }
    left_cat = left_totals.get("categoryTotals", {})
    right_cat = right_totals.get("categoryTotals", {})
    for key in sorted(set(left_cat.keys()) | set(right_cat.keys())):
        delta["categoryTotals"][key] = right_cat.get(key, 0) - left_cat.get(key, 0)
    return schemas.SnapshotCompareOut(left=left_out, right=right_out, delta=delta)


ROOT = Path(settings.static_dir).resolve()
app.mount("/static", StaticFiles(directory=str(ROOT)), name="static")


@app.get("/")
def root_page():
    return FileResponse(str(ROOT / "index.html"))
