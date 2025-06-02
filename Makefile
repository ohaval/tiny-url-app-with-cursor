.PHONY: lint lt e2e e2e-aws install cdk-synth cdk-bootstrap deploy destroy docker-build docker-up docker-down docker-test docker-setup docker-logs docker-clean

lint:
	pre-commit run --all-files

install:
	pip install -r requirements.txt

local-test lt:
	python -m pytest tests/component

# End-to-end tests work with both local containerized and deployed AWS services
# Local: python -m pytest tests/e2e/test_e2e.py -v
# AWS: API_ENDPOINT=https://api-url.execute-api.region.amazonaws.com/prod python -m pytest tests/e2e/test_e2e.py -v
e2e:
	python -m pytest tests/e2e/test_e2e.py -v --log-cli-level=INFO

# Run e2e tests against deployed AWS version (auto-detects API endpoint)
e2e-aws:
	@echo "🔍 Checking for deployed AWS stack..."
	@if ! command -v aws &> /dev/null; then \
		echo "❌ AWS CLI not found. Please install it first."; \
		exit 1; \
	fi; \
	ALL_STACKS=$$(aws cloudformation list-stacks --stack-status-filter CREATE_COMPLETE UPDATE_COMPLETE --query 'StackSummaries[?StackName!=`CDKToolkit`].StackName' --output text 2>/dev/null || echo ""); \
	if [ -z "$$ALL_STACKS" ]; then \
		echo "❌ No deployed AWS stacks found."; \
		echo "   Deploy the app first with: make deploy"; \
		exit 1; \
	fi; \
	STACK_COUNT=$$(echo "$$ALL_STACKS" | wc -w); \
	echo "✅ Found $$STACK_COUNT total stacks"; \
	TINY_STACKS=$$(echo "$$ALL_STACKS" | tr ' ' '\n' | grep -i -E '(tiny|url)' | head -3 | tr '\n' ' ' | sed 's/ $$//' || echo ""); \
	if [ -n "$$TINY_STACKS" ]; then \
		TARGET_STACK=$$(echo "$$TINY_STACKS" | awk '{print $$1}'); \
	else \
		echo "❌ No tiny-url related stacks found in $$STACK_COUNT total stacks."; \
		echo "   Deploy the tiny-url app first with: make deploy"; \
		exit 1; \
	fi; \
	echo "🔍 Using stack: $$TARGET_STACK"; \
	API_URL=$$(aws cloudformation describe-stacks --stack-name "$$TARGET_STACK" --query 'Stacks[0].Outputs[?contains(OutputValue, `execute-api`)].OutputValue' --output text 2>/dev/null | awk '{print $$1}' || echo ""); \
	if [ -z "$$API_URL" ]; then \
		echo "❌ Could not extract API endpoint from stack: $$TARGET_STACK"; \
		echo "   Make sure the stack has an API Gateway output."; \
		exit 1; \
	fi; \
	echo "✅ Found API endpoint: $$API_URL"; \
	echo "🧪 Running e2e tests against deployed AWS services..."; \
	API_ENDPOINT=$$API_URL python -m pytest tests/e2e/test_e2e.py -v --log-cli-level=INFO

cdk-synth:
	# Synthesizes CloudFormation templates from your CDK code.
	# Use to preview what will be deployed and validate infrastructure code before deployment.
	cdk synth

cdk-bootstrap:
	# Sets up required AWS infrastructure for CDK deployments (S3 bucket, IAM roles).
	# Run once per AWS account/region before first deployment or after major CDK upgrades.
	cdk bootstrap

deploy:
	cdk deploy --require-approval never

destroy:
	cdk destroy

# Docker commands for containerized development
docker-build:
	# Build Docker images for both microservices
	docker-compose build

docker-up:
	# Start all containerized services in detached mode
	docker-compose up -d

docker-down:
	# Stop and remove all containerized services
	docker-compose down

docker-setup:
	# Complete setup of local containerized development environment
	./scripts/setup-local-dev.sh

docker-test:
	# Run comprehensive tests against containerized services
	./scripts/test-services.sh

docker-logs:
	# View logs from all services
	docker-compose logs -f

docker-clean:
	# Clean up Docker resources (images, containers, volumes)
	docker-compose down -v
	docker system prune -f
