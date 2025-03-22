"""DynamoDB operations for URL shortening service."""

from datetime import datetime, timedelta

import boto3
from botocore.exceptions import ClientError


class DynamoDBOperations:
    """Handle DynamoDB operations for URL mappings."""

    def __init__(self, table_name: str) -> None:
        """Initialize DynamoDB operations.

        Args:
            table_name: Name of the DynamoDB table
        """
        self.dynamodb = boto3.resource("dynamodb")
        self.table = self.dynamodb.Table(table_name)

    def save_url_mapping(
        self, short_code: str, long_url: str
    ) -> bool:
        """Save URL mapping to DynamoDB."""
        now = datetime.utcnow()
        expires_at = int((now + timedelta(days=30)).timestamp())

        try:
            self.table.put_item(
                Item={
                    "short_code": short_code,
                    "creation_date": now.isoformat(),
                    "long_url": long_url,
                    "expires_at": expires_at,
                },
                ConditionExpression=(
                    "attribute_not_exists(short_code)"
                ),
            )
            return True
        except ClientError as e:
            if (
                e.response["Error"]["Code"]
                == "ConditionalCheckFailedException"
            ):
                return False
            raise
