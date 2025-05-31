# tiny-url-app-with-cursor

## Project Overview
A URL shortening service built with Python and AWS CDK, focusing on clean code and comprehensive testing.

For detailed information, see:
- [Architecture & Tech Stack](docs/ARCHITECTURE.md)
- [Features & Implementation](docs/FEATURES.md)
- [Kubernetes Learning Plan](docs/KUBERNETES_LEARNING_PLAN.md) - Learn K8s by migrating this app

## Development Workflow
1. Local Development
   ```bash
   python -m venv .venv
   source .venv/bin/activate
   make install
   ```

2. Testing & Linting
   ```bash
   # Run all local tests
   make lt

   # Run linting
   make lint

   # Run e2e tests against deployed API
   API_ENDPOINT=https://api-id.execute-api.region.amazonaws.com/prod make e2e
   ```

3. Deployment
   ```bash
   # Install AWS CDK CLI (if not already installed)
   npm install -g aws-cdk

   # Bootstrap CDK (first time only in each AWS account/region)
   make cdk-bootstrap

   # Deploy the stack
   make deploy

   # To destroy the deployed resources
   make destroy
   ```

4. Post-Deployment Validation
   ```bash
   # After deployment, the API URL will be displayed in the output
   # Use the base API URL (without /shorten) to run e2e tests against the deployed API
   # The tests will automatically construct the correct endpoints
   API_ENDPOINT=https://your-api-url.execute-api.region.amazonaws.com/prod make e2e

   # You can also test manually with curl
   curl -X POST https://your-api-url.execute-api.region.amazonaws.com/prod/shorten \
     -d '{"url":"https://example.com/long/path"}'

   # Or with a custom short code
   curl -X POST https://your-api-url.execute-api.region.amazonaws.com/prod/shorten \
     -d '{"url":"https://example.com/long/path", "custom_code":"my-link"}'
   ```

## Available Make Commands

| Command        | Description                                                  |
|----------------|--------------------------------------------------------------|
| `make install` | Install all required dependencies                            |
| `make lint`    | Run pre-commit hooks to lint all files                       |
| `make lt`      | Run all local tests                                          |
| `make e2e`     | Run end-to-end tests against deployed API (requires API_ENDPOINT)|
| `make cdk-synth` | Synthesize CloudFormation templates from CDK code          |
| `make cdk-bootstrap` | Bootstrap AWS resources for CDK deployments           |
| `make deploy`  | Deploy the application to AWS                               |
| `make destroy` | Remove all AWS resources created by this application        |

## Testing Strategy
- Component tests covering end-to-end flows:
  - URL creation flow
  - Real DynamoDB interactions (with moto mock)
  - Business logic through actual usage paths
- E2E tests for deployed API:
  - Tests against the live API endpoint
  - Validates production behavior
  - Verifies all error cases
- Focus on real user scenarios over isolated unit testing
