# Project Structure

```
tiny-url-app-with-cursor/
├── .github/
│   └── workflows/
│       ├── linting.yml          # GitHub Actions linting workflow
│       └── tests.yml            # GitHub Actions test workflow
├── docs/
│   ├── ARCHITECTURE.md          # System architecture documentation
│   ├── FEATURES.md              # Features and roadmap documentation
│   ├── KUBERNETES_LEARNING_PLAN.md  # Kubernetes learning documentation
│   └── structure.md             # This file - project structure
├── docker/
│   ├── redirect/
│   │   ├── app.py               # Flask app for redirect service
│   │   └── Dockerfile           # Docker config for redirect service
│   ├── shorten/
│   │   ├── app.py               # Flask app for shorten service
│   │   └── Dockerfile           # Docker config for shorten service
│   └── requirements-container.txt  # Container-specific dependencies
├── lib/
│   ├── __init__.py              # Python package marker
│   ├── README.md                # CDK library documentation
│   └── tiny_url_stack.py        # AWS CDK stack definition
├── scripts/
│   └── setup-local-dev.sh       # Local development setup script
├── src/
│   ├── handlers/
│   │   ├── redirect_url.py      # Lambda handler for URL redirects
│   │   └── shorten_url.py       # Lambda handler for URL shortening
│   ├── utils/
│   │   ├── api_client.py        # API client utilities
│   │   ├── api_gateway.py       # API Gateway utilities
│   │   ├── dynamo_ops.py        # DynamoDB operations
│   │   ├── short_code_generator.py  # Short code generation logic
│   │   └── url_validator.py     # URL validation utilities
│   └── __init__.py              # Python package marker
├── tests/
│   ├── component/
│   │   ├── conftest.py          # Component test configuration
│   │   ├── test_redirect_url.py # Component tests for redirect
│   │   └── test_shorten_url.py  # Component tests for shorten
│   └── e2e/
│       └── test_e2e.py          # End-to-end integration tests
├── .gitignore                   # Git ignore rules
├── .pre-commit-config.yaml      # Pre-commit hooks configuration
├── app.py                       # CDK application entry point
├── cdk.context.json             # CDK context configuration
├── cdk.json                     # CDK project configuration
├── docker-compose.yml           # Local development orchestration
├── Makefile                     # Build and development commands
├── pyproject.toml               # Python project configuration
├── README.md                    # Project documentation
└── requirements.txt             # Python dependencies
```

## Directory Descriptions

### Core Application Code
- **`src/`** - Main application source code
  - **`handlers/`** - AWS Lambda function handlers
  - **`utils/`** - Shared utility modules and business logic

### Infrastructure & Deployment
- **`lib/`** - AWS CDK infrastructure as code
- **`docker/`** - Docker containerization for local development
- **`scripts/`** - Development and deployment scripts

### Testing
- **`tests/`** - Test suite
  - **`component/`** - Unit/component tests with mocked dependencies
  - **`e2e/`** - End-to-end integration tests

### Documentation
- **`docs/`** - Project documentation and specifications

### CI/CD & Configuration
- **`.github/`** - GitHub Actions workflows
- **Configuration files** - Various project configuration files (CDK, Docker, Python, etc.)
