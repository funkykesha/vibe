from pathlib import Path
from contextlib import asynccontextmanager

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

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins,
    allow_credentials=True,
    allow_methods=["GET", "PATCH"],
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


ROOT = Path(settings.static_dir).resolve()
app.mount("/static", StaticFiles(directory=str(ROOT)), name="static")


@app.get("/")
def root_page():
    return FileResponse(str(ROOT / "index.html"))
