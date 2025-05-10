"""End-to-end tests for the deployed URL API.

These tests run against the actual deployed API endpoint in AWS.
The API endpoint URL should be provided via the API_ENDPOINT environment variable.

Example:
    API_ENDPOINT=https://0fllpafnie.execute-api.us-east-1.amazonaws.com/prod \
    python -m pytest tests/e2e/test_e2e.py -v
"""

import os
import re

import requests

# Get the API endpoint from environment variable
API_ENDPOINT = os.environ.get("API_ENDPOINT")
if not API_ENDPOINT:
    raise EnvironmentError(
        "API_ENDPOINT environment variable must be set to run E2E tests."
    )

# Ensure the endpoint has the correct format with trailing slash if needed
SHORTEN_ENDPOINT = (
    f"{API_ENDPOINT}/shorten"
    if not API_ENDPOINT.endswith("/shorten")
    else API_ENDPOINT
)


# URL Shortening Tests

def test_valid_url_shortening() -> None:
    """Test that a valid URL can be shortened and returns expected format."""
    # Arrange
    payload = {"url": "https://example.com/long/path"}

    # Act
    response = requests.post(SHORTEN_ENDPOINT, json=payload)
    response_data = response.json()

    # Assert
    assert response.status_code == 200
    assert "short_url" in response_data
    assert "expires_at" in response_data

    # Verify short URL format (base URL + 8 character code)
    short_url = response_data["short_url"]
    assert re.match(r"https://tiny\.url/[a-zA-Z0-9]{8}$", short_url)


def test_multiple_valid_urls_get_different_codes() -> None:
    """Test that different URLs get different short codes."""
    # Arrange
    payload1 = {"url": "https://example.com/path1"}
    payload2 = {"url": "https://example.com/path2"}

    # Act
    response1 = requests.post(SHORTEN_ENDPOINT, json=payload1)
    response2 = requests.post(SHORTEN_ENDPOINT, json=payload2)

    # Assert
    assert response1.status_code == 200
    assert response2.status_code == 200

    short_url1 = response1.json()["short_url"]
    short_url2 = response2.json()["short_url"]

    # Different URLs should get different short codes
    assert short_url1 != short_url2


def test_invalid_url() -> None:
    """Test that an invalid URL returns the appropriate error."""
    # Arrange
    payload = {"url": "not-valid-url"}

    # Act
    response = requests.post(SHORTEN_ENDPOINT, json=payload)
    response_data = response.json()

    # Assert
    assert response.status_code == 400
    assert "error" in response_data
    assert "URL must start with http://" in response_data["error"]


def test_missing_url() -> None:
    """Test that a missing URL returns the appropriate error."""
    # Arrange
    payload = {}

    # Act
    response = requests.post(SHORTEN_ENDPOINT, json=payload)
    response_data = response.json()

    # Assert
    assert response.status_code == 400
    assert "error" in response_data
    assert "URL is empty or missing" in response_data["error"]


def test_url_too_long() -> None:
    """Test that a URL exceeding maximum length returns an error."""
    # Arrange
    long_url = f"https://example.com/{'x' * 2048}"
    payload = {"url": long_url}

    # Act
    response = requests.post(SHORTEN_ENDPOINT, json=payload)
    response_data = response.json()

    # Assert
    assert response.status_code == 400
    assert "error" in response_data
    assert "length exceeds maximum" in response_data["error"]


# URL Redirection Tests

def test_url_redirection() -> None:
    """Test redirection for a valid short code."""
    # First create a shortened URL
    payload = {"url": "https://example.com/test-redirection"}
    response = requests.post(SHORTEN_ENDPOINT, json=payload)
    assert response.status_code == 200

    short_url = response.json()["short_url"]
    short_code = short_url.split("/")[-1]

    # Now test redirection
    redirect_url = f"{API_ENDPOINT}/{short_code}"
    redirect_response = requests.get(redirect_url, allow_redirects=False)

    # Check for 302 redirect status and proper headers
    assert redirect_response.status_code == 302
    assert redirect_response.headers.get("Location") == "https://example.com/test-redirection"
    assert "Cache-Control" in redirect_response.headers


def test_nonexistent_short_code() -> None:
    """Test behavior for a non-existent short code."""
    # Use a random short code that shouldn't exist
    redirect_url = f"{API_ENDPOINT}/nonexistent12345"
    response = requests.get(redirect_url)

    # Should return 404 for non-existent codes
    assert response.status_code == 404
    assert "error" in response.json()
    assert "not found" in response.json()["error"].lower()
