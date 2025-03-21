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
