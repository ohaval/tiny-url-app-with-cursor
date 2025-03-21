# tiny-url-app-with-cursor

## Project Overview
A URL shortening service built with Python and AWS CDK, focusing on clean code and comprehensive testing.

## Tech Stack
- **Backend**: Python 3.11
- **Infrastructure**: AWS CDK (Infrastructure as Code)
- **Cloud Provider**: AWS
- **Database**: DynamoDB
- **API**: AWS API Gateway + Lambda
- **Testing**: pytest, pytest-mock
- **Type Checking**: mypy
- **CI/CD**: GitHub Actions (TBD)

## Core Features
1. URL Shortening
   - Generate short URLs (8 characters)
   - Custom URL support (optional)
   - URL expiration (TTL)

2. URL Redirection
   - Fast redirect response
   - Handle invalid/expired URLs

3. Analytics
   - Click tracking
   - Unique visitors
   - Geographic distribution

## AWS Services
- Lambda for serverless functions
- DynamoDB for URL storage
- API Gateway for REST endpoints
- CloudWatch for monitoring
- CloudFront for caching (future)

## Development Workflow
1. Local Development
   ```bash
   python -m venv .venv
   source .venv/bin/activate
   pip install -r requirements.txt
   ```

2. Testing
   ```bash
   # Run unit tests
   pytest tests/unit

   # Run integration tests
   pytest tests/integration

   # Type checking
   mypy src/
   ```

3. Deployment
   ```bash
   cdk deploy
   ```

## Testing Strategy
- Unit tests for all business logic
- Integration tests for API endpoints
- Infrastructure tests for CDK stacks
- Mocked AWS services in tests
- Minimum 80% code coverage

## Initial Usage Estimates
- Storage: ~100 bytes per URL record
- Read/Write ratio: 10:1 (more reads than writes)
- Initial capacity: 10K URLs/month
- Expected latency: <100ms for redirects

## Project Structure
```
tiny-url/
├── src/
│   ├── handlers/         # Lambda functions
│   └── utils/           # Shared utilities
├── tests/
│   ├── unit/
│   └── integration/
├── lib/                 # CDK infrastructure
├── app.py              # CDK app entry
└── cdk.json           # CDK config
```

## Future Enhancements
- Custom domains support
- API key authentication
- Rate limiting
- QR code generation
- Link preview