#!/usr/bin/env python3
"""Entry point for the Tiny URL CDK application."""

import os
from aws_cdk import App, Environment

from lib.tiny_url_stack import TinyUrlStack

# Get environment variables
account = os.environ.get("CDK_DEFAULT_ACCOUNT")
region = os.environ.get("CDK_DEFAULT_REGION", "us-east-1")

app = App()

# Create stack in the specified environment
# If no account is specified, the stack will be environment-agnostic
env = Environment(account=account, region=region) if account else None

TinyUrlStack(
    app,
    "TinyUrlStack",
    env=env,
    description="URL shortening service infrastructure",
)

app.synth()
