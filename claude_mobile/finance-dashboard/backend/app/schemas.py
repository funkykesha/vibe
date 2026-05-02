from pydantic import BaseModel, ConfigDict


class AccountOut(BaseModel):
    id: int
    bank: str
    name: str
    type: str
    cat: str
    val: str
    currency: str

    model_config = ConfigDict(from_attributes=True)


class AccountPatch(BaseModel):
    val: str | None = None
    currency: str | None = None

    model_config = ConfigDict(extra="forbid")


class CategoryOut(BaseModel):
    id: int
    name: str
    pct: str

    model_config = ConfigDict(from_attributes=True)


class DeductionOut(BaseModel):
    id: int
    name: str
    val: str

    model_config = ConfigDict(from_attributes=True)


class SettingsOut(BaseModel):
    categories: list[CategoryOut]
    deductions: list[DeductionOut]
    usdRate: str
    mortgage: str


class SettingsPatch(BaseModel):
    categories: list[CategoryOut] | None = None
    deductions: list[DeductionOut] | None = None
    usdRate: str | None = None
    mortgage: str | None = None

    model_config = ConfigDict(extra="forbid")


class SalaryEventIn(BaseModel):
    eventDate: str
    eventType: str
    gross: str
    deductions: str
    net: str
    distribution: list[dict]

    model_config = ConfigDict(extra="forbid")


class SalaryEventOut(SalaryEventIn):
    id: int
    createdAt: str

    model_config = ConfigDict(from_attributes=True)


class SnapshotCreateIn(BaseModel):
    label: str | None = None

    model_config = ConfigDict(extra="forbid")


class SnapshotOut(BaseModel):
    id: int
    label: str
    timestamp: str
    payloadVersion: str
    mortgage: str
    usdRate: str
    accounts: list[dict]
    categories: list[dict]
    currencies: dict
    totals: dict


class SnapshotCompareOut(BaseModel):
    left: SnapshotOut
    right: SnapshotOut
    delta: dict
