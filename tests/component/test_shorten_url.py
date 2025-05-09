"""Component tests for URL shortening endpoint."""

import json
from typing import Any, Generator

import boto3
import pytest
from moto import mock_aws

from src.handlers.shorten_url import handler


@pytest.fixture
def dynamodb_table() -> Generator[Any, None, None]:
    """Set up DynamoDB test table."""
    with mock_aws():
        # Create test table
        dynamodb = boto3.resource("dynamodb", region_name="us-east-1")
        table = dynamodb.create_table(
            TableName="url_mappings",
            KeySchema=[
                {"AttributeName": "short_code", "KeyType": "HASH"}
            ],
            AttributeDefinitions=[
                {"AttributeName": "short_code", "AttributeType": "S"}
            ],
            BillingMode="PAY_PER_REQUEST",
        )

        yield table


def test_valid_url_shortening(dynamodb_table: Any) -> None:
    """Test successful URL shortening."""
    event = {
        "body": json.dumps(
            {"url": "https://example.com/very/long/url"}
        )
    }

    response = handler(event, None)

    assert response["statusCode"] == 200
    body = json.loads(response["body"])
    assert "short_url" in body
    assert body["short_url"].startswith("https://tiny.url/")
    assert len(body["short_url"].split("/")[-1]) == 8
    assert "expires_at" in body


def test_invalid_url(dynamodb_table: Any) -> None:
    """Test handling of invalid URL."""
    event = {"body": json.dumps({"url": "not-a-url"})}

    response = handler(event, None)

    assert response["statusCode"] == 400
    body = json.loads(response["body"])
    assert "error" in body
    assert "URL must start with http://" in body["error"]


def test_missing_url(dynamodb_table: Any) -> None:
    """Test handling of missing URL."""
    event = {"body": json.dumps({})}

    response = handler(event, None)

    assert response["statusCode"] == 400
    body = json.loads(response["body"])
    assert "error" in body
    assert "empty" in body["error"].lower()


def test_url_too_long(dynamodb_table: Any) -> None:
    """Test handling of URL that exceeds maximum length."""
    long_url = f"https://example.com/{'x' * 2048}"
    event = {"body": json.dumps({"url": long_url})}

    response = handler(event, None)

    assert response["statusCode"] == 400
    body = json.loads(response["body"])
    assert "error" in body
    assert "length exceeds maximum" in body["error"]


def test_custom_url_shortening(dynamodb_table: Any) -> None:
    """Test successful custom URL shortening."""
    custom_code = "my-custom-slug"
    event = {
        "body": json.dumps({
            "url": "https://example.com/very/long/url",
            "custom_code": custom_code
        })
    }

    response = handler(event, None)

    assert response["statusCode"] == 200
    body = json.loads(response["body"])
    assert "short_url" in body
    assert body["short_url"].endswith(f"/{custom_code}")
    assert "expires_at" in body


def test_custom_url_already_taken(dynamodb_table: Any) -> None:
    """Test handling of already taken custom URL."""
    custom_code = "taken-slug"

    # First create a URL with the custom code
    event1 = {
        "body": json.dumps({
            "url": "https://example.com/first/url",
            "custom_code": custom_code
        })
    }
    handler(event1, None)

    # Try to use the same custom code again
    event2 = {
        "body": json.dumps({
            "url": "https://example.com/second/url",
            "custom_code": custom_code
        })
    }
    response = handler(event2, None)

    assert response["statusCode"] == 409
    body = json.loads(response["body"])
    assert "error" in body
    assert "already in use" in body["error"]


def test_invalid_custom_code_format(dynamodb_table: Any) -> None:
    """Test handling of invalid custom code format."""
    event = {
        "body": json.dumps({
            "url": "https://example.com/valid/url",
            "custom_code": "invalid/code/with/slashes"
        })
    }

    response = handler(event, None)

    assert response["statusCode"] == 400
    body = json.loads(response["body"])
    assert "error" in body
    assert "must contain only" in body["error"]


def test_too_long_custom_code(dynamodb_table: Any) -> None:
    """Test handling of custom code that exceeds maximum length."""
    event = {
        "body": json.dumps({
            "url": "https://example.com/valid/url",
            "custom_code": "a" * 50  # Too long
        })
    }

    response = handler(event, None)

    assert response["statusCode"] == 400
    body = json.loads(response["body"])
    assert "error" in body
    assert "exceeds maximum length" in body["error"]
