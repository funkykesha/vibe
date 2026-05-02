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
