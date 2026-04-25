import os
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, declarative_base

# Default to SQLite for local development; switch to Postgres in production (.env)
SQLALCHEMY_DATABASE_URL = os.getenv("DATABASE_URL", "sqlite:///./finlink_users.db")

# SQLite requires a specific argument to handle threading. Postgres does not.
connect_args = {"check_same_thread": False} if SQLALCHEMY_DATABASE_URL.startswith("sqlite") else {}

engine = create_engine(SQLALCHEMY_DATABASE_URL, connect_args=connect_args)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base = declarative_base()

# Dependency Injection for database sessions
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()