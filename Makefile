.PHONY: lint lt e2e e2e-aws install cdk-synth cdk-bootstrap deploy destroy docker-build docker-up docker-down docker-setup docker-logs docker-clean table-peek table-peek-aws

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
	cd cdk && cdk synth

cdk-bootstrap:
	# Sets up required AWS infrastructure for CDK deployments (S3 bucket, IAM roles).
	# Run once per AWS account/region before first deployment or after major CDK upgrades.
	cd cdk && cdk bootstrap

deploy:
	cd cdk && cdk deploy --require-approval never

destroy:
	cd cdk && cdk destroy

# Docker commands for containerized development
docker-build:
	# Build Docker images for both microservices
	cd docker && docker compose build

docker-up:
	# Start all containerized services in detached mode
	cd docker && docker compose up -d

docker-down:
	# Stop and remove all containerized services
	cd docker && docker compose down

docker-setup:
	# Complete setup of local containerized development environment
	./scripts/setup-local-dev.sh

docker-logs:
	# View logs from all services
	cd docker && docker compose logs -f

docker-clean:
	# Clean up Docker resources (images, containers, volumes)
	cd docker && docker compose down -v
	docker system prune -f

table-peek:
	# Peek at DynamoDB table contents (first 3 rows + count)
	@echo "🔍 DynamoDB Table: url_mappings"
	@echo "📊 Connection: http://localhost:8002"
	@echo ""
	@if ! docker ps | grep -q dynamodb-local; then \
		echo "❌ DynamoDB Local not running. Start with: make docker-up"; \
		exit 1; \
	fi; \
	TOTAL_COUNT=$$(aws dynamodb scan --table-name url_mappings --endpoint-url http://localhost:8002 --select COUNT --query 'Count' --output text 2>/dev/null || echo "0"); \
	echo "📈 Total items: $$TOTAL_COUNT"; \
	echo ""; \
	if [ "$$TOTAL_COUNT" = "0" ]; then \
		echo "📭 Table is empty"; \
	else \
		echo "📄 First 3 rows:"; \
		echo ""; \
		aws dynamodb scan --table-name url_mappings --endpoint-url http://localhost:8002 --limit 3 --query 'Items' --output json 2>/dev/null | \
		jq -r '(["Short Code", "Long URL", "Created", "Expires"] | @tsv), (["----------", "--------", "-------", "-------"] | @tsv), (.[] | [.short_code.S, (.long_url.S | if length > 50 then .[0:47] + "..." else . end), (.creation_date.S | split("T")[0]), (.expires_at.N | tonumber | strftime("%Y-%m-%d"))] | @tsv)' | \
		column -t -s $$'\t'; \
	fi; \
	echo ""

table-peek-aws:
	# Peek at AWS-deployed DynamoDB table contents (first 3 rows + count)
	@echo "🔍 DynamoDB Table: url_mappings (AWS)"
	@echo "🌍 Connection: AWS Production"
	@echo ""
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
	echo "🔍 Found $$STACK_COUNT total stacks"; \
	TINY_STACKS=$$(echo "$$ALL_STACKS" | tr ' ' '\n' | grep -i -E '(tiny|url)' | head -3 | tr '\n' ' ' | sed 's/ $$//' || echo ""); \
	if [ -n "$$TINY_STACKS" ]; then \
		TARGET_STACK=$$(echo "$$TINY_STACKS" | awk '{print $$1}'); \
	else \
		echo "❌ No tiny-url related stacks found in $$STACK_COUNT total stacks."; \
		echo "   Deploy the tiny-url app first with: make deploy"; \
		exit 1; \
	fi; \
	echo "✅ Using stack: $$TARGET_STACK"; \
	TABLE_NAME=$$(aws cloudformation describe-stacks --stack-name "$$TARGET_STACK" --query 'Stacks[0].Outputs[?OutputKey==`TableName`].OutputValue' --output text 2>/dev/null || echo "url_mappings"); \
	if [ -z "$$TABLE_NAME" ]; then \
		TABLE_NAME="url_mappings"; \
	fi; \
	echo "📊 Table: $$TABLE_NAME"; \
	echo ""; \
	TOTAL_COUNT=$$(aws dynamodb scan --table-name "$$TABLE_NAME" --select COUNT --query 'Count' --output text 2>/dev/null || echo "0"); \
	echo "📈 Total items: $$TOTAL_COUNT"; \
	echo ""; \
	if [ "$$TOTAL_COUNT" = "0" ]; then \
		echo "📭 Table is empty"; \
	else \
		echo "📄 First 3 rows:"; \
		echo ""; \
		aws dynamodb scan --table-name "$$TABLE_NAME" --limit 3 --query 'Items' --output json 2>/dev/null | \
		jq -r '(["Short Code", "Long URL", "Created", "Expires"] | @tsv), (["----------", "--------", "-------", "-------"] | @tsv), (.[] | [.short_code.S, (.long_url.S | if length > 50 then .[0:47] + "..." else . end), (.creation_date.S | split("T")[0]), (.expires_at.N | tonumber | strftime("%Y-%m-%d"))] | @tsv)' | \
		column -t -s $$'\t'; \
	fi; \
	echo ""
