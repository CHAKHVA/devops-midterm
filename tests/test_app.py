import pytest

from src.main import app as flask_app


@pytest.fixture
def client():
    flask_app.config["TESTING"] = True
    with flask_app.test_client() as client:
        yield client


def test_index_returns_200(client):
    response = client.get("/")
    assert response.status_code == 200


def test_index_contains_form(client):
    response = client.get("/")
    assert b"form" in response.data


def test_greet_returns_personalized_message(client):
    response = client.post("/greet", data={"name": "Alex"})
    assert response.status_code == 200
    assert b"Alex" in response.data


def test_greet_missing_name_returns_400(client):
    response = client.post("/greet", data={"name": ""})
    assert response.status_code == 400


def test_health_returns_ok(client):
    response = client.get("/health")
    assert response.status_code == 200
    data = response.get_json()
    assert data["status"] == "ok"
    assert "version" in data
