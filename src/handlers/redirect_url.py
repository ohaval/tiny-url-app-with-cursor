"""Lambda handler for URL redirection endpoint."""

import logging
import os
from datetime import datetime
from typing import Any, Dict

# Add compatibility for both direct imports and importing through tests
try:
    from utils.api_gateway import create_response, create_redirect_response
    from utils.dynamo_ops import DynamoDBOperations
except ModuleNotFoundError:
    from src.utils.api_gateway import create_response, create_redirect_response
    from src.utils.dynamo_ops import DynamoDBOperations

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Initialize DynamoDB operations outside handler for performance
TABLE_NAME = "url_mappings"
REGION_NAME = os.environ.get("AWS_DEFAULT_REGION", "us-east-1")
dynamo_ops = DynamoDBOperations(table_name=TABLE_NAME, region_name=REGION_NAME)


def handler(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """Handle URL redirection requests.

    Args:
        event: API Gateway event containing short code in path parameters
        context: Lambda context

    Returns:
        API Gateway response with redirect or error
    """
    try:
        logger.info(f"Received redirect request: {event}")

        # Extract short code from path parameters
        path_parameters = event.get("pathParameters", {})
        if not path_parameters or not path_parameters.get("shortCode"):
            logger.warning("No short code provided in path parameters")
            return create_response(
                400, {"error": "No short code provided"}
            )

        short_code = path_parameters.get("shortCode")
        logger.info(f"Looking up short code: {short_code}")

        # Lookup URL in DynamoDB
        found, url_data = dynamo_ops.get_url_mapping(short_code)

        if not found or not url_data:
            logger.warning(f"Short code not found: {short_code}")
            return create_response(
                404, {"error": f"Short URL '{short_code}' not found"}
            )

        # Check if URL has expired
        expires_at = url_data.get("expires_at", 0)
        now = int(datetime.utcnow().timestamp())

        if expires_at and expires_at < now:
            logger.warning(f"Short code expired: {short_code}")
            return create_response(
                410, {"error": f"Short URL '{short_code}' has expired"}
            )

        # Return redirect to original URL
        long_url = url_data.get("long_url")
        logger.info(f"Redirecting to: {long_url}")

        # Log this redirect for analytics (future enhancement)
        # This would be an async operation, perhaps using SQS

        return create_redirect_response(long_url)

    except Exception as e:
        logger.error(f"Error processing redirect: {str(e)}", exc_info=True)
        return create_response(
            500, {"error": "Internal server error"}
        )
