import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from database import Base, get_db
from main_prod import app
import models

# Test database
SQLALCHEMY_DATABASE_URL = "sqlite:///./test.db"
engine = create_engine(SQLALCHEMY_DATABASE_URL, connect_args={"check_same_thread": False})
TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

def override_get_db():
    try:
        db = TestingSessionLocal()
        yield db
    finally:
        db.close()

app.dependency_overrides[get_db] = override_get_db

@pytest.fixture
def client():
    Base.metadata.create_all(bind=engine)
    with TestClient(app) as c:
        yield c
    Base.metadata.drop_all(bind=engine)

def test_health_check(client):
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json()["status"] == "healthy"

def test_register_user(client):
    response = client.post("/register", json={
        "email": "test@example.com",
        "password": "TestPass123"
    })
    assert response.status_code == 200
    assert response.json()["email"] == "test@example.com"

def test_login(client):
    # Register user first
    client.post("/register", json={
        "email": "test@example.com", 
        "password": "TestPass123"
    })
    
    # Login
    response = client.post("/token", data={
        "username": "test@example.com",
        "password": "TestPass123"
    })
    assert response.status_code == 200
    assert "access_token" in response.json()

def test_create_loan_unauthorized(client):
    response = client.post("/loans", json={
        "borrower_name": "Test Corp",
        "loan_amount": 1000000
    })
    assert response.status_code == 401

def test_invalid_password(client):
    response = client.post("/register", json={
        "email": "test@example.com",
        "password": "weak"
    })
    assert response.status_code == 422
