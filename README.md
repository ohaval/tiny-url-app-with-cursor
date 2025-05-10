# tiny-url-app-with-cursor

## Project Overview
A URL shortening service built with Python and AWS CDK, focusing on clean code and comprehensive testing.

## Tech Stack
- **Backend**: Python 3.11
- **Infrastructure**: AWS CDK (Infrastructure as Code)
- **Cloud Provider**: AWS
- **Database**: DynamoDB
- **API**: AWS API Gateway + Lambda
- **Testing**: pytest
- **CI/CD**: GitHub Actions

## Core Features
1. URL Shortening ✅
   - Generate short URLs (8 characters) ✅
   - Custom URL support ✅
   - URL expiration (TTL) ✅

2. URL Redirection ✅
   - Fast redirect response ✅
   - Handle invalid/expired URLs ✅

3. Analytics (Planned)
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
   # Use this URL to run e2e tests against the deployed API
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
│   ├── component/       # Component tests
│   └── e2e/             # End-to-end tests for deployed API
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
    "url": "https://example.com/very/long/url",
    "custom_code": "my-custom-code"  // Optional
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
  - Support custom short codes up to 30 characters (letters, numbers, underscores, hyphens)
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

- **E2E Tests**:
  - Tests against the deployed API
  - Verifies expected responses and error handling
  - Confirms behavior in production environment

### Step 2: URL Redirection Endpoint

#### PRD
- **Endpoint**: GET /{short_code}
- **Input**: Short code in URL path
- **Output**:
  - HTTP 302 redirect to the original URL
  - Headers:
    - Location: {original_long_url}
    - Cache-Control: public, max-age=86400 (1 day)
- **Requirements**:
  - Fast redirection (<100ms response time)
  - Log access for analytics (asynchronously)
  - Return 404 for non-existent short codes
  - Return 410 (Gone) for expired links
  - Handle both custom and generated short codes
  - Support HTTPS redirects

#### Technical Implementation
- **Infrastructure**:
  - Lambda function: `redirect_url` ✅
  - API Gateway: REST API endpoint with path parameter ✅
  - CloudWatch Logs for access tracking ✅
  - Optional: SQS queue for analytics processing (planned)

- **Components**:
  1. URL Lookup Service ✅
     - Fast DynamoDB lookup by short code ✅
     - TTL expiration check ✅
     - Optimize for read performance ✅

  2. Redirect Handler ✅
     - Generate proper HTTP 302 response ✅
     - Set appropriate headers ✅
     - Handle edge cases ✅

  3. Analytics Logger (async)
     - Log redirect events (planned)
     - Capture user-agent, referrer, timestamp (planned)
     - Designed for minimal impact on redirect latency (planned)

- **Error Cases**:
  - Short code not found ✅
  - Expired URL (TTL passed) ✅
  - DynamoDB failures ✅
  - Invalid short code format ✅

#### Performance Considerations
- Use API Gateway caching for frequently accessed URLs
- Consider DynamoDB DAX for high-volume scenarios
- Implement proper CloudWatch alarms for latency monitoring

#### Testing
- **Component Tests**: ✅
  - Valid redirection flow ✅
  - Non-existent short code handling ✅
  - Expired URL handling ✅
  - Header verification ✅

- **E2E Tests**:
  - Verify actual redirects with HTTP clients (planned)
  - Measure redirect latency (planned)
  - Test cache behavior (planned)
  - Confirm analytics data is captured correctly (planned)
