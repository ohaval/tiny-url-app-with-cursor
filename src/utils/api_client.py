"""
Unified API Client for Tiny URL service.

This client can work against different environments:
- Local containerized services (Docker)
- Deployed AWS services (Lambda + API Gateway)

The client automatically detects the environment and handles the differences
in URL structure, response formats, and networking.
"""

import logging
import os
from typing import Dict, Any, Optional
from dataclasses import dataclass

import requests

# Configure logger for this module
logger = logging.getLogger(__name__)


@dataclass
class APIResponse:
    """Standardized response object for API calls."""

    status_code: int
    json_data: Optional[Dict[str, Any]] = None
    headers: Optional[Dict[str, str]] = None
    text: Optional[str] = None

    @property
    def success(self) -> bool:
        """Check if the response indicates success."""
        return 200 <= self.status_code < 300

    def json(self) -> Dict[str, Any]:
        """Get JSON response data."""
        if self.json_data is None:
            raise ValueError("Response does not contain JSON data")
        return self.json_data


class TinyURLClient:
    """
    Unified client for Tiny URL API.

    Supports both local containerized services and deployed AWS services.
    Automatically handles environment differences.
    """

    def __init__(self, base_url: Optional[str] = None, timeout: int = 30):
        """
        Initialize the API client.

        Args:
            base_url: Base URL for the API. If None, auto-detects from
                     environment.
            timeout: Request timeout in seconds.
        """
        self.timeout = timeout
        self.base_url = self._determine_base_url(base_url)
        self.shorten_endpoint = f"{self.base_url}/shorten"

        # Detect environment type
        self.is_local = self._is_local_environment()

        # Different redirect base URLs for different environments
        if self.is_local:
            # Local: redirect service runs on different port
            self.redirect_base = "http://localhost:8001"
        else:
            # AWS: same base URL for all endpoints
            self.redirect_base = self.base_url

    def _determine_base_url(self, provided_url: Optional[str]) -> str:
        """Determine the base URL for API calls."""
        if provided_url:
            # Clean up provided URL (remove /shorten suffix if present)
            base_url = provided_url.rstrip("/shorten").rstrip("/")
            logger.info(f"Using provided base URL: {base_url}")
            return base_url

        # Auto-detect from environment
        if api_endpoint := os.getenv("API_ENDPOINT"):
            base_url = api_endpoint.rstrip("/shorten").rstrip("/")
            logger.info(f"Using API_ENDPOINT environment variable: {base_url}")
            return base_url

        # Default to local containerized services
        base_url = "http://localhost:8000"
        logger.info(f"Using default local containerized base URL: {base_url}")
        return base_url

    def _is_local_environment(self) -> bool:
        """Check if we're targeting local containerized services."""
        return "localhost" in self.base_url or "127.0.0.1" in self.base_url

    def _make_request(
        self,
        method: str,
        url: str,
        **kwargs
    ) -> APIResponse:
        """Make HTTP request and return standardized response."""
        try:
            response = requests.request(
                method=method,
                url=url,
                timeout=self.timeout,
                **kwargs
            )

            # Try to parse JSON, but don't fail if it's not JSON
            json_data = None
            try:
                json_data = response.json()
            except (ValueError, requests.exceptions.JSONDecodeError):
                pass

            return APIResponse(
                status_code=response.status_code,
                json_data=json_data,
                headers=dict(response.headers),
                text=response.text
            )
        except requests.exceptions.RequestException as e:
            # Handle network errors
            raise ConnectionError(f"Failed to connect to {url}: {e}")

    def health_check(self, service: str = "shorten") -> APIResponse:
        """
        Check health of a specific service.

        Args:
            service: Service to check ("shorten" or "redirect")

        Returns:
            APIResponse with health status
        """
        if service == "shorten":
            url = f"{self.base_url}/health"
        elif service == "redirect":
            url = f"{self.redirect_base}/health"
        else:
            raise ValueError(f"Unknown service: {service}")

        return self._make_request("GET", url)

    def get_service_info(self, service: str = "shorten") -> APIResponse:
        """
        Get service information and available endpoints.

        Args:
            service: Service to query ("shorten" or "redirect")

        Returns:
            APIResponse with service information
        """
        if service == "shorten":
            url = self.base_url
        elif service == "redirect":
            url = self.redirect_base
        else:
            raise ValueError(f"Unknown service: {service}")

        return self._make_request("GET", url)

    def shorten_url(
        self,
        url: str,
        custom_code: Optional[str] = None
    ) -> APIResponse:
        """
        Shorten a URL.

        Args:
            url: The URL to shorten
            custom_code: Optional custom short code

        Returns:
            APIResponse with shortened URL data
        """
        payload = {"url": url}
        if custom_code:
            payload["custom_code"] = custom_code

        return self._make_request(
            "POST",
            self.shorten_endpoint,
            json=payload,
            headers={"Content-Type": "application/json"}
        )

    def redirect(
        self,
        short_code: str,
        follow_redirects: bool = False
    ) -> APIResponse:
        """
        Test redirection for a short code.

        Args:
            short_code: The short code to test
            follow_redirects: Whether to follow the redirect

        Returns:
            APIResponse with redirect information
        """
        url = f"{self.redirect_base}/{short_code}"
        return self._make_request(
            "GET",
            url,
            allow_redirects=follow_redirects
        )

    def extract_short_code(self, shorten_response: APIResponse) -> str:
        """
        Extract short code from a shorten response.

        Args:
            shorten_response: Response from shorten_url call

        Returns:
            The short code string

        Raises:
            ValueError: If short code cannot be extracted
        """
        if not shorten_response.success:
            raise ValueError("Cannot extract short code from failed response")

        response_data = shorten_response.json()
        short_url = response_data.get("short_url")

        if not short_url:
            raise ValueError("No short_url found in response")

        # Extract the last part of the URL (the short code)
        return short_url.split("/")[-1]

    def __repr__(self) -> str:
        """Return string representation of the client."""
        env_type = "local" if self.is_local else "deployed"
        return (f"TinyURLClient(base_url='{self.base_url}', "
                f"environment='{env_type}')")
