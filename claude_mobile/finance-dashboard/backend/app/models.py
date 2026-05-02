from sqlalchemy import Column, Integer, String, Text

from .db import Base


class Account(Base):
    __tablename__ = "accounts"

    id = Column(Integer, primary_key=True, index=True)
    bank = Column(String, nullable=False)
    name = Column(String, nullable=False)
    type = Column(String, nullable=False)
    cat = Column(String, nullable=False)
    val = Column(String, nullable=False, default="")
    currency = Column(String, nullable=False, default="RUB")


class Category(Base):
    __tablename__ = "categories"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, nullable=False)
    pct = Column(String, nullable=False, default="")


class Deduction(Base):
    __tablename__ = "deductions"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, nullable=False)
    val = Column(String, nullable=False, default="")


class AppSettings(Base):
    __tablename__ = "app_settings"

    id = Column(Integer, primary_key=True, index=True)
    usd_rate = Column(String, nullable=False, default="80.33")
    mortgage = Column(String, nullable=False, default="11948583")


class SalaryEvent(Base):
    __tablename__ = "salary_events"

    id = Column(Integer, primary_key=True, index=True)
    event_date = Column(String, nullable=False)
    event_type = Column(String, nullable=False)
    gross = Column(String, nullable=False, default="")
    deductions = Column(String, nullable=False, default="")
    net = Column(String, nullable=False, default="")
    distribution_json = Column(Text, nullable=False, default="[]")
    created_at = Column(String, nullable=False)


class Snapshot(Base):
    __tablename__ = "snapshots"

    id = Column(Integer, primary_key=True, index=True)
    label = Column(String, nullable=False)
    timestamp = Column(String, nullable=False)
    payload_version = Column(String, nullable=False, default="v1")
    accounts_json = Column(Text, nullable=False)
    categories_json = Column(Text, nullable=False)
    currencies_json = Column(Text, nullable=False)
    totals_json = Column(Text, nullable=False)
    mortgage = Column(String, nullable=False, default="")
    usd_rate = Column(String, nullable=False, default="")
