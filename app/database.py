from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
from .config import settings

# Determine if we're using SQLite or PostgreSQL
if settings.database_url.startswith("sqlite"):
    # SQLite needs check_same_thread=False
    engine = create_engine(
        settings.database_url, 
        connect_args={"check_same_thread": False}
    )
else:
    # PostgreSQL doesn't need connect_args
    engine = create_engine(settings.database_url)

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()