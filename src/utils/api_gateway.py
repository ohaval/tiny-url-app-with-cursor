"""Utilities for API Gateway response handling."""

import json
from typing import Any, Dict


def create_response(
    status_code: int, body: Dict[str, Any]
) -> Dict[str, Any]:
    """Create API Gateway response with given status code and body.

    Args:
        status_code: HTTP status code to return
        body: Response body to serialize to JSON

    Returns:
        Formatted API Gateway response dictionary
    """
    return {
        "statusCode": status_code,
        "headers": {"Content-Type": "application/json"},
        "body": json.dumps(body),
    }


def create_redirect_response(
    location: str, cache_ttl: int = 86400
) -> Dict[str, Any]:
    """Create API Gateway redirect response.

    Args:
        location: URL to redirect to
        cache_ttl: Cache TTL in seconds (default: 86400 - 1 day)

    Returns:
        Formatted API Gateway response dictionary for redirection
    """
    return {
        "statusCode": 302,
        "headers": {
            "Location": location,
            "Cache-Control": f"public, max-age={cache_ttl}"
        },
        "body": ""
    }
