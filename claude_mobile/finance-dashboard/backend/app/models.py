from sqlalchemy import Column, Float, Integer, String

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
