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

2. Containerized Development
   ```bash
   # Setup and start containerized services
   make docker-setup

   # View logs
   make docker-logs

   # Stop services
   make docker-down
   ```

3. Testing & Linting
   ```bash
   # Run all local tests
   make lt

   # Run linting
   make lint

   # Run e2e tests (works with both local containerized and deployed AWS)
   make e2e

   # Run e2e tests against deployed AWS (auto-detects API endpoint)
   make e2e-aws

   # Run e2e tests against specific AWS deployment
   API_ENDPOINT=https://api-id.execute-api.region.amazonaws.com/prod make e2e
   ```

4. Deployment
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

5. Post-Deployment Validation
   ```bash
   # After deployment, test against the deployed API (auto-detects endpoint)
   make e2e-aws

   # Or manually specify the endpoint
   API_ENDPOINT=https://your-api-url.execute-api.region.amazonaws.com/prod make e2e
   ```

## API Client

The project includes a unified API client (`src.utils.api_client.TinyURLClient`) that provides a clean interface for interacting with the Tiny URL service across different environments.

### Client Features
- **Environment Auto-Detection**: Automatically detects local vs deployed environments
- **Unified Interface**: Same code works against containerized and AWS-deployed services
- **Error Handling**: Comprehensive error handling with meaningful error messages
- **Flexible Configuration**: Can be configured via environment variables or direct parameters

### Client Usage
```python
from src.utils.api_client import TinyURLClient

# Auto-detect environment (local containerized by default)
client = TinyURLClient()

# Or specify a specific API endpoint
client = TinyURLClient(base_url="https://your-api-url.execute-api.region.amazonaws.com/prod")

# Shorten a URL
response = client.shorten_url("https://example.com")
if response.success:
    data = response.json()
    short_url = data["short_url"]

# Test redirection
short_code = client.extract_short_code(response)
redirect_response = client.redirect(short_code)

# Compose operations as needed for your use case
```

### Environment Configuration
- **Local Containerized**: Uses `http://localhost:8000` (shorten) and `http://localhost:8001` (redirect)
- **AWS Deployed**: Uses `API_ENDPOINT` environment variable or provided base_url
- **Auto-Detection**: Client automatically handles URL differences between environments

## Available Make Commands

| Command        | Description                                                  |
|----------------|--------------------------------------------------------------|
| `make install` | Install all required dependencies                            |
| `make lint`    | Run pre-commit hooks to lint all files                       |
| `make lt`      | Run all local tests                                          |
| `make e2e`     | Run end-to-end tests (works with both local and AWS)        |
| `make e2e-aws` | Run e2e tests against deployed AWS (auto-detects endpoint)  |
| `make docker-setup` | Setup and start containerized development environment |
| `make docker-down` | Stop containerized services                        |
| `make docker-test` | Run tests against containerized services (bash-based) |
| `make docker-logs` | View logs from containerized services              |
| `make cdk-synth` | Synthesize CloudFormation templates from CDK code          |
| `make cdk-bootstrap` | Bootstrap AWS resources for CDK deployments           |
| `make deploy`  | Deploy the application to AWS                               |
| `make destroy` | Remove all AWS resources created by this application        |

## Testing Strategy
- **Component Tests (`make lt`)**: Unit tests with mocked dependencies
  - URL creation flow
  - Real DynamoDB interactions (with moto mock)
  - Business logic through actual usage paths
- **End-to-End Tests (`make e2e`)**: Complete API tests using TinyURLClient
  - Works against both local containerized and deployed AWS services
  - Tests full HTTP request/response cycle
  - Demonstrates client usage and capabilities
  - Validates complete workflows end-to-end
- **Docker Tests (`make docker-test`)**: Bash-based smoke tests for containerized services
  - Simple health and functionality checks
  - Container orchestration validation

The e2e tests serve dual purpose: comprehensive testing AND demonstration of the API client across all environments.
