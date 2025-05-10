"""CDK Stack for URL shortening service."""

from typing import Any

from aws_cdk import (
    Duration,
    Stack,
    RemovalPolicy,
    CfnOutput,
)
from aws_cdk import aws_dynamodb as dynamodb
from aws_cdk import aws_lambda as lambda_
from aws_cdk import aws_apigateway as apigateway
from constructs import Construct


class TinyUrlStack(Stack):
    """Stack for URL shortening service infrastructure."""

    def __init__(
        self, scope: Construct, construct_id: str, **kwargs: Any
    ) -> None:
        """Initialize the stack.

        Args:
            scope: CDK app or parent stack
            construct_id: ID of the construct
            kwargs: Additional keyword arguments
        """
        super().__init__(scope, construct_id, **kwargs)

        # 1. Create DynamoDB table
        url_table = self._create_dynamo_table()

        # 2. Create Lambda functions
        shorten_lambda = self._create_shorten_lambda(url_table)
        redirect_lambda = self._create_redirect_lambda(url_table)

        # 3. Create API Gateway
        api = self._create_api_gateway(shorten_lambda, redirect_lambda)

        # 4. Output the API Gateway URL
        CfnOutput(
            self,
            "ApiUrl",
            value=f"{api.url}shorten",
            description="URL for the /shorten endpoint",
        )

    def _create_dynamo_table(self) -> dynamodb.Table:
        """Create DynamoDB table for URL mappings.

        Returns:
            The DynamoDB table
        """
        return dynamodb.Table(
            self,
            "UrlMappings",
            table_name="url_mappings",
            partition_key=dynamodb.Attribute(
                name="short_code",
                type=dynamodb.AttributeType.STRING
            ),
            sort_key=dynamodb.Attribute(
                name="creation_date",
                type=dynamodb.AttributeType.STRING
            ),
            billing_mode=dynamodb.BillingMode.PAY_PER_REQUEST,
            time_to_live_attribute="expires_at",
            # For dev; use RETAIN in prod
            removal_policy=RemovalPolicy.DESTROY,
        )

    def _create_shorten_lambda(
        self, table: dynamodb.Table
    ) -> lambda_.Function:
        """Create Lambda function for URL shortening.

        Args:
            table: The DynamoDB table for URL mappings

        Returns:
            The Lambda function
        """
        lambda_fn = lambda_.Function(
            self,
            "ShortenUrlFunction",
            function_name="tiny_url_shorten",
            runtime=lambda_.Runtime.PYTHON_3_11,
            code=lambda_.Code.from_asset(
                ".",
                bundling={
                    "image": lambda_.Runtime.PYTHON_3_11.bundling_image,
                    "command": [
                        "bash", "-c",
                        "pip install validators -t /asset-output && "
                        "cp -au /asset-input/src/* /asset-output/"
                    ]
                }
            ),
            handler="handlers.shorten_url.handler",
            timeout=Duration.seconds(10),
            memory_size=128,
            environment={
                "TABLE_NAME": table.table_name,
                # Replace with actual domain
                "BASE_URL": "https://tiny.url",
            },
        )

        # Grant Lambda permissions to access DynamoDB
        table.grant_read_write_data(lambda_fn)

        return lambda_fn

    def _create_redirect_lambda(
        self, table: dynamodb.Table
    ) -> lambda_.Function:
        """Create Lambda function for URL redirection.

        Args:
            table: The DynamoDB table for URL mappings

        Returns:
            The Lambda function
        """
        lambda_fn = lambda_.Function(
            self,
            "RedirectUrlFunction",
            function_name="tiny_url_redirect",
            runtime=lambda_.Runtime.PYTHON_3_11,
            code=lambda_.Code.from_asset(
                ".",
                bundling={
                    "image": lambda_.Runtime.PYTHON_3_11.bundling_image,
                    "command": [
                        "bash", "-c",
                        "cp -au /asset-input/src/* /asset-output/"
                    ]
                }
            ),
            handler="handlers.redirect_url.handler",
            timeout=Duration.seconds(3),  # Shorter timeout for redirects
            memory_size=128,
            environment={
                "TABLE_NAME": table.table_name,
            },
        )

        # Grant Lambda read-only permissions to DynamoDB
        table.grant_read_data(lambda_fn)

        return lambda_fn

    def _create_api_gateway(
        self, shorten_lambda: lambda_.Function,
        redirect_lambda: lambda_.Function
    ) -> apigateway.RestApi:
        """Create API Gateway for the URL shortening service.

        Args:
            shorten_lambda: The Lambda function for shortening URLs
            redirect_lambda: The Lambda function for redirecting URLs

        Returns:
            The REST API
        """
        # Create REST API
        api = apigateway.RestApi(
            self,
            "TinyUrlApi",
            rest_api_name="TinyUrl API",
            description="API for URL shortening service",
            default_cors_preflight_options=apigateway.CorsOptions(
                allow_origins=apigateway.Cors.ALL_ORIGINS,
                allow_methods=apigateway.Cors.ALL_METHODS,
            ),
        )

        # Add /shorten endpoint
        shorten = api.root.add_resource("shorten")

        # CORS parameters
        cors_header = {
            "method.response.header.Access-Control-Allow-Origin": True,
        }
        cors_integration = {
            "method.response.header.Access-Control-Allow-Origin": "'*'",
        }

        # Add POST method for shortening
        shorten.add_method(
            "POST",
            apigateway.LambdaIntegration(
                shorten_lambda,
                proxy=True,
                integration_responses=[
                    apigateway.IntegrationResponse(
                        status_code="200",
                        response_parameters=cors_integration,
                    )
                ],
            ),
            method_responses=[
                apigateway.MethodResponse(
                    status_code="200",
                    response_parameters=cors_header,
                )
            ],
        )

        # Add /{shortCode} endpoint for redirects
        short_code = api.root.add_resource("{shortCode}")

        # Add GET method for redirection
        # Include additional headers for redirects
        redirect_cors_header = {
            "method.response.header.Access-Control-Allow-Origin": True,
            "method.response.header.Location": True,
            "method.response.header.Cache-Control": True,
        }

        short_code.add_method(
            "GET",
            apigateway.LambdaIntegration(
                redirect_lambda,
                proxy=True,
            ),
            method_responses=[
                apigateway.MethodResponse(
                    status_code="302",
                    response_parameters=redirect_cors_header,
                ),
                apigateway.MethodResponse(
                    status_code="404",
                    response_parameters=cors_header,
                ),
                apigateway.MethodResponse(
                    status_code="410",
                    response_parameters=cors_header,
                ),
            ],
        )

        return api
