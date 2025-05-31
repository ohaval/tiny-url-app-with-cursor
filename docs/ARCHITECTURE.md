# Architecture

## Tech Stack
- **Backend**: Python 3.11
- **Infrastructure**: AWS CDK (Infrastructure as Code)
- **Cloud Provider**: AWS
- **Database**: DynamoDB
- **API**: AWS API Gateway + Lambda
- **Testing**: pytest
- **CI/CD**: GitHub Actions

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
├── app.py              # CDK app entry
└── cdk.json           # CDK config
```

## Performance Considerations
- Use API Gateway caching for frequently accessed URLs
- Consider DynamoDB DAX for high-volume scenarios
- Implement proper CloudWatch alarms for latency monitoring

## Initial Usage Estimates
- Storage: ~100 bytes per URL record
- Read/Write ratio: 10:1 (more reads than writes)
- Initial capacity: 10K URLs/month
- Expected latency: <100ms for redirects
