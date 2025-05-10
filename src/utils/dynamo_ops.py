"""DynamoDB operations for URL shortening service."""

from datetime import datetime, timedelta
from typing import Dict, Any, Optional, Tuple

import boto3
from botocore.exceptions import ClientError


class DynamoDBOperations:
    """Handle DynamoDB operations for URL mappings."""

    def __init__(self, table_name: str, region_name: str = "us-east-1") -> None:
        """Initialize DynamoDB operations.

        Args:
            table_name: Name of the DynamoDB table
            region_name: AWS region name (default: us-east-1)
        """
        self.dynamodb = boto3.resource("dynamodb", region_name=region_name)
        self.table = self.dynamodb.Table(table_name)

    def save_url_mapping(
        self, short_code: str, long_url: str
    ) -> bool:
        """Save URL mapping to DynamoDB."""
        now = datetime.utcnow()
        expires_at = int((now + timedelta(days=30)).timestamp())

        # First check if the short_code already exists
        try:
            response = self.table.query(
                KeyConditionExpression="short_code = :code",
                ExpressionAttributeValues={":code": short_code},
                Limit=1
            )

            if response.get("Items"):
                # Short code already exists
                return False

            # Short code doesn't exist, save it
            self.table.put_item(
                Item={
                    "short_code": short_code,
                    "creation_date": now.isoformat(),
                    "long_url": long_url,
                    "expires_at": expires_at,
                }
            )
            return True
        except ClientError:
            # Handle unexpected errors
            raise

    def get_url_mapping(
        self, short_code: str
    ) -> Tuple[bool, Optional[Dict[str, Any]]]:
        """Get URL mapping from DynamoDB.

        Args:
            short_code: The short code to look up

        Returns:
            Tuple containing:
                - Boolean indicating if mapping was found
                - Dictionary with URL data if found, None otherwise
        """
        try:
            response = self.table.query(
                KeyConditionExpression="short_code = :code",
                ExpressionAttributeValues={":code": short_code},
                Limit=1,
                ScanIndexForward=False  # Get the most recent entry first
            )

            items = response.get("Items", [])
            if not items:
                return False, None

            return True, items[0]
        except ClientError:
            return False, None
