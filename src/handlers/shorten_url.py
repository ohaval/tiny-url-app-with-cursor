"""Lambda handler for URL shortening endpoint."""

import json
import os
from datetime import datetime, timedelta
from typing import Any, Dict, Tuple, Union

from src.utils.api_gateway import create_response
from src.utils.dynamo_ops import DynamoDBOperations
from src.utils.short_code_generator import generate_short_code
from src.utils.url_validator import validate_url

# Initialize DynamoDB operations outside handler for performance
TABLE_NAME = "url_mappings"
dynamo_ops = DynamoDBOperations(table_name=TABLE_NAME)

MAX_RETRIES = 3


def validate_request(event: Dict[str, Any]) -> Tuple[
    bool, Union[str, Dict[str, Any]]
]:
    """Validate the incoming request.

    Args:
        event: API Gateway event

    Returns:
        Tuple containing:
            - Boolean indicating if validation passed
            - Either the validated URL or an error response object
    """
    # Parse request body
    try:
        body = json.loads(event.get("body", "{}"))
    except json.JSONDecodeError:
        return False, create_response(
            400, {"error": "Invalid JSON in request body"}
        )

    # Check if URL is provided
    url = body.get("url")
    if not url:
        return False, create_response(
            400, {"error": "URL is empty or missing"}
        )

    # Validate URL
    is_valid, error = validate_url(url)
    if not is_valid:
        return False, create_response(400, {"error": error})

    return True, url


def handler(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """Handle URL shortening requests.

    Args:
        event: API Gateway event
        context: Any

    Returns:
        API Gateway response
    """
    try:
        # Validate request
        is_valid, result = validate_request(event)
        if not is_valid:
            return result

        url = result

        # Retry logic handles potential collisions when generating
        # short codes. If a generated code already exists in the
        # database, we need to try creating a new one to avoid
        # conflicts.
        for _ in range(MAX_RETRIES):
            short_code = generate_short_code()
            if dynamo_ops.save_url_mapping(short_code, url):
                expires_at = (
                    datetime.utcnow() + timedelta(days=30)
                ).isoformat()
                base_url = os.environ.get(
                    "BASE_URL", "https://tiny.url"
                )
                return create_response(
                    200,
                    {
                        "short_url": f"{base_url}/{short_code}",
                        "expires_at": expires_at,
                    },
                )

        # If all retries failed
        return create_response(
            409, {"error": "Failed to generate unique short code"}
        )
    except Exception:
        return create_response(
            500, {"error": "Internal server error"}
        )
