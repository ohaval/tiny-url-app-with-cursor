# CDK Infrastructure

This directory contains the AWS CDK (Cloud Development Kit) infrastructure code for the Tiny URL service.

## Overview

The infrastructure is defined using AWS CDK in Python, which allows us to define cloud resources using code.

## Components

- `tiny_url_stack.py`: Main stack that defines all resources:
  - DynamoDB table for URL mappings
  - Lambda function for the URL shortening endpoint
  - API Gateway for REST API
  - IAM roles and permissions

## Future Additions

- Redirect Lambda function and endpoint
- CloudFront distribution for caching
- Analytics capabilities
- Custom domain name

## Deployment

To deploy this infrastructure:

1. Ensure your AWS credentials are configured
2. Run `cdk bootstrap` (first time only)
3. Run `cdk deploy`

To destroy the infrastructure:

```bash
cdk destroy
```
