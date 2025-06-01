"""
End-to-end tests for the Tiny URL API using TinyURLClient.

These tests work against both local containerized services and deployed AWS services.
The environment is auto-detected or configured via the API_ENDPOINT environment variable.

Examples:
    # Test against local containerized services (default)
    python -m pytest tests/e2e/test_e2e.py -v

    # Test against deployed AWS services
    API_ENDPOINT=https://api-id.execute-api.region.amazonaws.com/prod python -m pytest tests/e2e/test_e2e.py -v
"""

import pytest
import time
from src.utils.api_client import TinyURLClient


class TestTinyURLAPI:
    """End-to-end tests for the Tiny URL API."""

    @pytest.fixture
    def client(self):
        """Create API client instance."""
        return TinyURLClient()

    def test_health_checks(self, client):
        """Test health endpoints for both services."""
        # Skip health checks for AWS deployments as they don't have health endpoints
        if not client.is_local:
            pytest.skip("AWS deployments don't have health endpoints")

        # Test shorten service health
        health_response = client.health_check("shorten")
        assert health_response.success, f"Shorten health check failed: {health_response.text}"

        # Test redirect service health
        health_response = client.health_check("redirect")
        assert health_response.success, f"Redirect health check failed: {health_response.text}"

    def test_basic_url_shortening(self, client):
        """Test basic URL shortening functionality."""
        test_url = "https://www.example.com"

        response = client.shorten_url(test_url)
        assert response.success, f"URL shortening failed: {response.text}"

        data = response.json()
        assert "short_url" in data
        assert "expires_at" in data

        # Verify short URL format - different for local vs AWS
        short_url = data["short_url"]
        if client.is_local:
            # Local: should contain redirect base URL
            assert client.redirect_base in short_url
        else:
            # AWS: may use different domain format (e.g., tiny.url)
            assert short_url.startswith(("http://", "https://"))
            assert "/" in short_url  # Should have a path component

    def test_custom_short_code(self, client):
        """Test URL shortening with custom short code."""
        test_url = "https://www.github.com"
        # Make unique custom code using timestamp
        timestamp = int(time.time())
        custom_code = f"github-{timestamp}"

        response = client.shorten_url(test_url, custom_code=custom_code)
        assert response.success, f"Custom code shortening failed: {response.text}"

        data = response.json()
        short_url = data["short_url"]
        assert custom_code in short_url

    def test_invalid_url_handling(self, client):
        """Test error handling for invalid URLs."""
        invalid_url = "not-a-valid-url"

        response = client.shorten_url(invalid_url)
        assert not response.success
        assert response.status_code == 400
        assert "error" in response.json()

    def test_missing_url_handling(self, client):
        """Test error handling for missing URL."""
        # This will cause JSON parsing to create empty dict
        response = client._make_request("POST", client.shorten_endpoint,
                                        json={},
                                        headers={"Content-Type": "application/json"})
        assert response.status_code == 400
        assert "error" in response.json()
        assert "URL is empty or missing" in response.json()["error"]

    def test_url_redirection(self, client):
        """Test URL redirection functionality."""
        test_url = "https://www.python.org"

        # First shorten the URL
        shorten_response = client.shorten_url(test_url)
        assert shorten_response.success

        short_code = client.extract_short_code(shorten_response)

        # Test redirect
        redirect_response = client.redirect(short_code, follow_redirects=False)
        assert redirect_response.status_code == 302

        # Check Location header
        location = (redirect_response.headers.get("Location") or
                    redirect_response.headers.get("location"))
        assert location == test_url

    def test_nonexistent_short_code(self, client):
        """Test handling of non-existent short codes."""
        fake_code = "nonexistent123"

        response = client.redirect(fake_code, follow_redirects=False)
        assert response.status_code == 404
        assert "error" in response.json()

    def test_complete_workflow(self, client):
        """Test complete URL shortening and redirection workflow."""
        test_url = "https://docs.python.org/3/"

        # Step 1: Shorten URL
        shorten_response = client.shorten_url(test_url)
        assert shorten_response.success, f"Shorten failed: {shorten_response.text}"

        short_code = client.extract_short_code(shorten_response)

        # Step 2: Test redirect
        redirect_response = client.redirect(short_code, follow_redirects=False)
        assert redirect_response.status_code == 302

        # Step 3: Verify redirect location
        location = (redirect_response.headers.get("Location") or
                    redirect_response.headers.get("location"))
        assert location == test_url

        # Verify we got reasonable values
        assert len(short_code) > 0

    def test_multiple_urls_unique_codes(self, client):
        """Test that different URLs get different short codes."""
        test_urls = [
            "https://www.google.com",
            "https://stackoverflow.com",
            "https://www.reddit.com"
        ]

        short_codes = []

        for url in test_urls:
            response = client.shorten_url(url)
            assert response.success

            short_code = client.extract_short_code(response)
            short_codes.append(short_code)

            # Test each redirect works
            redirect_response = client.redirect(short_code, follow_redirects=False)
            assert redirect_response.status_code == 302

        # Verify all short codes are unique
        assert len(set(short_codes)) == len(short_codes)

    def test_client_environment_detection(self, client):
        """Test that client correctly detects its environment."""
        # Verify environment-specific URL configuration
        if client.is_local:
            assert "localhost" in client.base_url
            assert client.redirect_base == "http://localhost:8001"
        else:
            # AWS environment
            assert client.redirect_base == client.base_url
            assert "execute-api" in client.base_url or "amazonaws.com" in client.base_url
