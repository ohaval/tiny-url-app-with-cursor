"""Shared fixtures for component tests."""

import os
from typing import Any, Generator

import boto3
import pytest
from moto import mock_aws


@pytest.fixture
def dynamodb_table() -> Generator[Any, None, None]:
    """Set up DynamoDB test table."""
    # Mock the BASE_URL environment variable needed by the shorten handler
    os.environ["BASE_URL"] = "https://tiny.url"

    with mock_aws():
        # Create test table
        dynamodb = boto3.resource("dynamodb", region_name="us-east-1")
        table = dynamodb.create_table(
            TableName="url_mappings",
            KeySchema=[
                {"AttributeName": "short_code", "KeyType": "HASH"},
                {"AttributeName": "creation_date", "KeyType": "RANGE"}
            ],
            AttributeDefinitions=[
                {"AttributeName": "short_code", "AttributeType": "S"},
                {"AttributeName": "creation_date", "AttributeType": "S"}
            ],
            BillingMode="PAY_PER_REQUEST",
        )

        yield table
