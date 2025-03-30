"""Lambda handler for URL shortening endpoint."""

import json
import logging
import os
from datetime import datetime, timedelta
from typing import Any, Dict, Tuple, Union

# Add compatibility for both direct imports and importing through tests
try:
    from utils.api_gateway import create_response
    from utils.dynamo_ops import DynamoDBOperations
    from utils.short_code_generator import generate_short_code
    from utils.url_validator import validate_url
except ModuleNotFoundError:
    from src.utils.api_gateway import create_response
    from src.utils.dynamo_ops import DynamoDBOperations
    from src.utils.short_code_generator import generate_short_code
    from src.utils.url_validator import validate_url

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Initialize DynamoDB operations outside handler for performance
TABLE_NAME = "url_mappings"
REGION_NAME = os.environ.get("AWS_DEFAULT_REGION", "us-east-1")
dynamo_ops = DynamoDBOperations(table_name=TABLE_NAME, region_name=REGION_NAME)

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
    logger.info("Validating request")
    # Parse request body
    try:
        body = json.loads(event.get("body", "{}"))
        logger.info(f"Request body: {body}")
    except json.JSONDecodeError:
        logger.error("Invalid JSON in request body")
        return False, create_response(
            400, {"error": "Invalid JSON in request body"}
        )

    # Check if URL is provided
    url = body.get("url")
    if not url:
        logger.warning("URL is empty or missing")
        return False, create_response(
            400, {"error": "URL is empty or missing"}
        )

    # Validate URL
    is_valid, error = validate_url(url)
    if not is_valid:
        logger.warning(f"Invalid URL: {error}")
        return False, create_response(400, {"error": error})

    logger.info("URL validation successful")
    return True, url


def handler(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """Handle URL shortening requests.

    Args:
        event: API Gateway event
        context: Any

    Returns:
        API Gateway response
    """
    logger.info(f"Received event: {json.dumps(event)}")

    try:
        # Validate request
        is_valid, result = validate_request(event)
        if not is_valid:
            return result

        url = result
        logger.info(f"Processing valid URL: {url}")

        # Retry logic handles potential collisions when generating
        # short codes. If a generated code already exists in the
        # database, we need to try creating a new one to avoid
        # conflicts.
        for attempt in range(MAX_RETRIES):
            logger.info(
                f"Attempt {attempt+1} of {MAX_RETRIES} to generate short URL"
            )
            short_code = generate_short_code()
            logger.info(f"Generated short code: {short_code}")

            if dynamo_ops.save_url_mapping(short_code, url):
                expires_at = (
                    datetime.utcnow() + timedelta(days=30)
                ).isoformat()
                base_url = os.environ.get(
                    "BASE_URL", "https://tiny.url"
                )
                short_url = f"{base_url}/{short_code}"
                logger.info(
                    f"Successfully created short URL: {short_url}"
                )

                return create_response(
                    200,
                    {
                        "short_url": short_url,
                        "expires_at": expires_at,
                    },
                )

        # If all retries failed
        logger.error("Failed to generate unique short code after max retries")
        return create_response(
            409, {"error": "Failed to generate unique short code"}
        )
    except Exception as e:
        logger.error(f"Unexpected error: {str(e)}", exc_info=True)
        return create_response(
            500, {"error": "Internal server error"}
        )
