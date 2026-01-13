from sqlalchemy import create_engine, event
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import QueuePool
import os
import logging

# Production database configuration
SQLALCHEMY_DATABASE_URL = os.getenv(
    "DATABASE_URL", "postgresql://user:password@localhost/creditsentinel"
)

# Production engine with connection pooling
engine = create_engine(
    SQLALCHEMY_DATABASE_URL,
    poolclass=QueuePool,
    pool_size=10,
    max_overflow=20,
    pool_pre_ping=True,
    pool_recycle=3600,
    echo=os.getenv("SQL_DEBUG", "false").lower() == "true"
)

# Add connection event listeners for production monitoring
@event.listens_for(engine, "connect")
def set_sqlite_pragma(dbapi_connection, connection_record):
    if "sqlite" in SQLALCHEMY_DATABASE_URL:
        cursor = dbapi_connection.cursor()
        cursor.execute("PRAGMA foreign_keys=ON")
        cursor.close()

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

def get_db():
    db = SessionLocal()
    try:
        yield db
    except Exception as e:
        db.rollback()
        logging.error(f"Database error: {e}")
        raise
    finally:
        db.close()

def init_db():
    """Initialize database with proper error handling"""
    try:
        Base.metadata.create_all(bind=engine)
        logging.info("Database initialized successfully")
    except Exception as e:
        logging.error(f"Database initialization failed: {e}")
        raise
