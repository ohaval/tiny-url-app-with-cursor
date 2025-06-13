# Project Structure

```
tiny-url-app-with-cursor/
├── .github/
│   └── workflows/
│       ├── linting.yml          # GitHub Actions linting workflow
│       └── tests.yml            # GitHub Actions test workflow
├── cdk/                         # AWS CDK deployment files
│   ├── lib/
│   │   ├── __init__.py          # Python package marker
│   │   ├── README.md            # CDK library documentation
│   │   └── tiny_url_stack.py    # AWS CDK stack definition
│   ├── app.py                   # CDK application entry point
│   ├── cdk.context.json         # CDK context configuration
│   └── cdk.json                 # CDK project configuration
├── docker/                      # Docker deployment files
│   ├── redirect/
│   │   ├── app.py               # Flask app for redirect service
│   │   └── Dockerfile           # Docker config for redirect service
│   ├── shorten/
│   │   ├── app.py               # Flask app for shorten service
│   │   └── Dockerfile           # Docker config for shorten service
│   ├── docker-compose.yml       # Local development orchestration
│   └── requirements-container.txt  # Container-specific dependencies
├── docs/
│   ├── ARCHITECTURE.md          # System architecture documentation
│   ├── FEATURES.md              # Features and roadmap documentation
│   ├── KUBERNETES_LEARNING_PLAN.md  # Kubernetes learning documentation
│   └── structure.md             # This file - project structure
├── scripts/
│   └── setup-local-dev.sh       # Local development setup script
├── src/                         # Shared application source code
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
├── tests/                       # Shared test suite
│   ├── component/
│   │   ├── conftest.py          # Component test configuration
│   │   ├── test_redirect_url.py # Component tests for redirect
│   │   └── test_shorten_url.py  # Component tests for shorten
│   └── e2e/
│       └── test_e2e.py          # End-to-end integration tests
├── .gitignore                   # Git ignore rules
├── .pre-commit-config.yaml      # Pre-commit hooks configuration
├── Makefile                     # Build and development commands
├── pyproject.toml               # Python project configuration
├── README.md                    # Project documentation
└── requirements.txt             # Python dependencies
```

## Directory Descriptions

### Deployment-Specific Directories
- **`cdk/`** - AWS CDK deployment files and infrastructure as code
  - Contains all CDK-specific files: stack definitions, CDK app, and configuration
  - Run CDK commands from this directory (handled by Makefile)
- **`docker/`** - Docker deployment files and local development
  - Contains all Docker-specific files: containers, compose, and container dependencies
  - Run Docker commands from this directory (handled by Makefile)

### Shared Application Code
- **`src/`** - Core application source code (used by both deployments)
  - **`handlers/`** - AWS Lambda function handlers (also used by Docker services)
  - **`utils/`** - Shared utility modules and business logic

### Shared Components
- **`tests/`** - Test suite (works with both deployment types)
  - **`component/`** - Unit/component tests with mocked dependencies
  - **`e2e/`** - End-to-end integration tests (auto-detects deployment environment)
- **`docs/`** - Project documentation and specifications
- **`scripts/`** - Development and deployment scripts (can be used by both)
- **`.github/`** - GitHub Actions workflows (tests both deployment types)

### Configuration Files
- **Root configuration files** - Shared project configuration (Python, Git, etc.)

## Benefits of This Structure
1. **Clear separation of concerns** - CDK and Docker files are isolated
2. **Shared core logic** - Source code is reused between deployments
3. **Unified testing** - Same test suite validates both deployment types
4. **Cleaner organization** - Easier to understand what files belong to which deployment method
5. **Easier maintenance** - Changes to deployment-specific files don't affect the other deployment type

## Key Changes Made
✅ **Reorganization completed successfully:**
- Moved CDK files (`lib/`, `app.py`, `cdk.json`, `cdk.context.json`) to `cdk/` directory
- Moved `docker-compose.yml` to `docker/` directory
- Updated Makefile to run CDK commands from `cdk/` directory
- Updated Makefile to run Docker commands from `docker/` directory
- Updated CDK stack asset paths to reference parent directory for source code
- Updated docker-compose.yml context to use parent directory
- All tests and linting still pass ✅
- CDK synth works correctly ✅
- Docker build works correctly ✅
