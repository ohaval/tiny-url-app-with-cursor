.PHONY: lint lt e2e e2e-aws e2e-k8s install cdk-synth cdk-bootstrap deploy destroy docker-build docker-down docker-setup docker-logs docker-clean k8s-setup k8s-down k8s-clean k8s-status table-peek table-peek-aws

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

# Run e2e tests against local Kubernetes deployment
e2e-k8s:
	@echo "🔍 Checking for local Kubernetes cluster..."
	@if ! command -v kubectl &> /dev/null; then \
		echo "❌ kubectl not found. Please install it first."; \
		exit 1; \
	fi; \
	if ! kubectl config current-context | grep -q "kind-tiny-url-local"; then \
		echo "❌ Not connected to tiny-url-local cluster."; \
		echo "   Run 'make k8s-setup' first or switch context."; \
		exit 1; \
	fi; \
	if ! kubectl get pods -n tiny-url | grep -q "Running"; then \
		echo "❌ No running pods found in tiny-url namespace."; \
		echo "   Run 'make k8s-setup' to deploy services."; \
		exit 1; \
	fi; \
	echo "✅ Kubernetes cluster and services ready"; \
	echo "🛑 Stopping Docker Compose services (if running)..."; \
	make docker-down 2>/dev/null || true; \
	echo "🔄 Setting up port forwarding..."; \
	echo "   • Shorten service: localhost:8000 → shorten-service:8000"; \
	echo "   • Redirect service: localhost:8001 → redirect-service:8001"; \
	(kubectl port-forward service/shorten-service 8000:8000 -n tiny-url > /dev/null 2>&1 &); \
	(kubectl port-forward service/redirect-service 8001:8001 -n tiny-url > /dev/null 2>&1 &); \
	echo "⏳ Waiting for port forwards to be ready..."; \
	sleep 5; \
	echo "✅ Port forwarding established"; \
	echo "🧪 Running e2e tests against local Kubernetes..."; \
	if python -m pytest tests/e2e/test_e2e.py -v --log-cli-level=INFO; then \
		echo "✅ E2E tests passed!"; \
		EXIT_CODE=0; \
	else \
		echo "❌ E2E tests failed!"; \
		EXIT_CODE=1; \
	fi; \
	echo "🧹 Cleaning up port forwards..."; \
	pkill -f "kubectl port-forward.*tiny-url" 2>/dev/null || true; \
	sleep 2; \
	echo "✅ Cleanup complete"; \
	exit $$EXIT_CODE

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

# Kubernetes commands for local development
k8s-setup:
	# Complete setup of local Kubernetes environment with kind cluster
	./scripts/setup-k8s-local.sh

k8s-down:
	# Remove all Kubernetes resources (keeps cluster running)
	./scripts/cleanup-k8s-local.sh

k8s-clean:
	# Destroy the entire kind cluster and all resources
	./scripts/destroy-k8s-local.sh

k8s-status:
	# Show status of local Kubernetes deployment
	@echo "🔍 Kubernetes Cluster Status"
	@echo ""
	@if kind get clusters | grep -q "^tiny-url-local$$"; then \
		echo "✅ Cluster: tiny-url-local (running)"; \
		kubectl config current-context; \
		echo ""; \
		echo "📊 Pods:"; \
		kubectl get pods -n tiny-url 2>/dev/null || echo "No pods found (namespace might not exist)"; \
		echo ""; \
		echo "🌐 Services:"; \
		kubectl get services -n tiny-url 2>/dev/null || echo "No services found (namespace might not exist)"; \
	else \
		echo "❌ Cluster: tiny-url-local (not found)"; \
		echo "   Run 'make k8s-setup' to create the cluster"; \
	fi

table-peek:
	# Peek at DynamoDB table contents (first 3 rows + count)
	@echo "🔍 DynamoDB Table: url_mappings"
	@echo "📊 Connection: http://localhost:8002"
	@echo ""
	@if ! docker ps | grep -q dynamodb-local; then \
		echo "❌ DynamoDB Local not running. Start with: make docker-setup"; \
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
