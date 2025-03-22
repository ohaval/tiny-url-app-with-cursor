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
   # Install AWS CDK CLI (if not already installed)
   npm install -g aws-cdk

   # Bootstrap CDK (first time only in each AWS account/region)
   make cdk-bootstrap

   # Deploy the stack
   make cdk-deploy

   # To destroy the deployed resources
   make cdk-destroy
   ```

## Testing Strategy
- Component tests covering end-to-end flows:
  - URL creation and redirection flows
  - Real DynamoDB interactions
  - API Gateway integration
  - Business logic through actual usage paths
- E2E tests in dev environment for critical paths
- Infrastructure tests for CDK stacks
- Focus on real user scenarios over isolated unit testing

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

## Feature Implementation Steps

### Step 1: URL Shortening Endpoint

#### PRD
- **Endpoint**: POST /shorten
- **Input**:
  ```json
  {
    "url": "https://example.com/very/long/url"
  }
  ```
- **Output**:
  ```json
  {
    "short_url": "https://tiny.url/abc123",
    "expires_at": "2024-04-21T04:04:51Z"  // 30 days from creation
  }
  ```
- **Requirements**:
  - Generate 8-character unique short codes
  - Validate input URL format
  - 30-day expiration by default
  - Return 400 for invalid URLs
  - Return 409 if short code already exists (retry with new code)
  - Maximum URL length: 2048 characters

#### Technical Implementation
- **Infrastructure**:
  - DynamoDB table: `url_mappings`
    - PK: short_code (String)
    - SK: creation_date (String)
    - Attributes:
      - long_url (String)
      - expires_at (Number) - TTL
      - created_at (String)
  - Lambda function: `shorten_url`
  - API Gateway: REST API endpoint

- **Components**:
  1. URL Validator
     - Check URL format
     - Verify max length
     - Ensure protocol (http/https)

  2. Short Code Generator
     - 8 chars [a-zA-Z0-9]
     - Collision detection

  3. DynamoDB Operations
     - Save mapping
     - Handle duplicates

- **Error Cases**:
  - Invalid URL format
  - URL too long
  - Generation retries exceeded
  - DynamoDB failures

#### Testing
- **Component Tests**:
  - Valid URL shortening flow
  - Invalid URL handling
  - Duplicate short code handling
  - URL validation edge cases
