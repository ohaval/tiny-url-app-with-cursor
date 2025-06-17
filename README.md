# tiny-url-app-with-cursor

## Project Overview
A URL shortening service built with Python and AWS CDK, focusing on clean code and comprehensive testing.

For detailed information, see:
- [Architecture & Tech Stack](docs/ARCHITECTURE.md)
- [Features & Implementation](docs/FEATURES.md)

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

3. Kubernetes Development
   ```bash
   # Setup and start local Kubernetes environment
   make k8s-setup

   # Check status
   make k8s-status

   # Stop services (keeps cluster running)
   make k8s-down

   # Destroy entire cluster
   make k8s-clean
   ```

4. Testing & Linting
   ```bash
   # Run all local tests
   make lt

   # Run linting
   make lint

   # Run e2e tests against different environments
   make e2e        # Docker Compose (default)
   make e2e-k8s    # Local Kubernetes
   make e2e-aws    # Deployed AWS (auto-detects)
   ```

5. Deployment
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

6. Post-Deployment Validation
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
| `make e2e-k8s` | Run e2e tests against local Kubernetes deployment           |
| `make docker-setup` | Setup and start containerized development environment |
| `make docker-down` | Stop containerized services                        |
| `make docker-logs` | View logs from containerized services              |
| `make k8s-setup` | Setup and start local Kubernetes environment              |
| `make k8s-down` | Remove Kubernetes resources (keeps cluster running)        |
| `make k8s-clean` | Destroy the entire kind cluster and all resources         |
| `make k8s-status` | Show status of local Kubernetes deployment               |
| `make cdk-synth` | Synthesize CloudFormation templates from CDK code          |
| `make cdk-bootstrap` | Bootstrap AWS resources for CDK deployments           |
| `make deploy`  | Deploy the application to AWS                               |
| `make destroy` | Remove all AWS resources created by this application        |

## Testing Strategy
- **Component Tests (`make lt`)**: Unit tests with mocked dependencies
  - URL creation flow
  - Real DynamoDB interactions (with moto mock)
  - Business logic through actual usage paths
- **End-to-End Tests**: Complete API tests using TinyURLClient
  - `make e2e` - Tests against local containerized services (Docker Compose)
  - `make e2e-aws` - Tests against deployed AWS services (auto-detects endpoint)
  - `make e2e-k8s` - Tests against local Kubernetes deployment (via port forwarding)
  - Tests full HTTP request/response cycle
  - Demonstrates client usage and capabilities
  - Validates complete workflows end-to-end

The e2e tests serve dual purpose: comprehensive testing AND demonstration of the API client across all environments.
