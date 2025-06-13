# Architecture

## Tech Stack
- **Backend**: Python 3.11
- **Infrastructure**: AWS CDK (Infrastructure as Code)
- **Cloud Provider**: AWS
- **Database**: DynamoDB
- **API**: AWS API Gateway + Lambda
- **Testing**: pytest
- **CI/CD**: GitHub Actions

## Deployment Options

### Local Development Environment
- **Containerization**: Docker Compose
- **Services**:
  - Shorten service (port 8000)
  - Redirect service (port 8001)
  - DynamoDB Local (port 8002)
- **Networking**: Docker bridge network
- **Use Case**: Development, testing, local experimentation

### Production Environment
- **Infrastructure**: AWS Serverless
- **Services**:
  - Lambda functions (shorten & redirect)
  - API Gateway (REST API)
  - DynamoDB table
- **Use Case**: Production deployment, high availability

## AWS Services
- Lambda for serverless functions
- DynamoDB for URL storage
- API Gateway for REST endpoints
- CloudWatch for monitoring
- CloudFront for caching (future)

## Project Structure
```
tiny-url/
├── src/
│   ├── handlers/         # Lambda functions
│   └── utils/           # Shared utilities
├── tests/
│   ├── component/       # Component tests
│   └── e2e/             # End-to-end tests for deployed API
├── lib/                 # CDK infrastructure
├── docker/              # Docker containerization
│   ├── shorten/         # Shorten service container
│   └── redirect/        # Redirect service container
├── scripts/             # Development scripts
├── app.py              # CDK app entry
├── docker-compose.yml  # Local development orchestration
└── cdk.json           # CDK config
```

## Testing Strategy
- **Component Tests**: Unit tests with mocked dependencies
- **E2E Tests**: Unified testing framework that works with both local Docker and AWS deployments
- **Environment Auto-Detection**: Tests automatically detect and adapt to deployment environment
- **Cross-Environment Validation**: Same test suite validates both deployment options

## Performance Considerations
- Use API Gateway caching for frequently accessed URLs
- Consider DynamoDB DAX for high-volume scenarios
- Implement proper CloudWatch alarms for latency monitoring

## Initial Usage Estimates
- Storage: ~100 bytes per URL record
- Read/Write ratio: 10:1 (more reads than writes)
- Initial capacity: 10K URLs/month
- Expected latency: <100ms for redirects
