"""Lambda handler for URL shortening endpoint."""

import json
import os
from datetime import datetime, timedelta
from typing import Any, Dict

from aws_lambda_powertools import Logger, Tracer
from aws_lambda_powertools.utilities.typing import LambdaContext

from src.utils.api_gateway import create_response
from src.utils.dynamo_ops import DynamoDBOperations
from src.utils.short_code_generator import generate_short_code
from src.utils.url_validator import validate_url

logger = Logger()
tracer = Tracer()

# Initialize DynamoDB operations outside handler for performance
TABLE_NAME = "url_mappings"
dynamo_ops = DynamoDBOperations(table_name=TABLE_NAME)

MAX_RETRIES = 3


@logger.inject_lambda_context
@tracer.capture_lambda_handler
def handler(
    event: Dict[str, Any], context: LambdaContext
) -> Dict[str, Any]:
    """Handle URL shortening requests.

    Args:
        event: API Gateway event
        context: Lambda context

    Returns:
        API Gateway response
    """
    try:
        body = json.loads(event.get("body", "{}"))
        url = body.get("url")

        # Validate URL
        is_valid, error = validate_url(url)
        if not is_valid:
            return create_response(400, {"error": error})

        # Generate and save short code with retries
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

        return create_response(
            409, {"error": "Failed to generate unique short code"}
        )

    except json.JSONDecodeError:
        return create_response(
            400, {"error": "Invalid JSON in request body"}
        )
    except Exception:
        logger.exception("Unexpected error")
        return create_response(
            500, {"error": "Internal server error"}
        )
