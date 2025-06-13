#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
DYNAMODB_ENDPOINT="http://localhost:8002"
TABLE_NAME="url_mappings"
SHORTEN_SERVICE_URL="http://localhost:8000"
REDIRECT_SERVICE_URL="http://localhost:8001"

# Set default AWS region if not already set (needed for DynamoDB Local)
export AWS_DEFAULT_REGION=${AWS_DEFAULT_REGION:-us-east-1}

echo -e "${GREEN}🚀 Setting up local development environment for tiny-url-app${NC}"

# Function to check if a service is running
check_service() {
    local url=$1
    local service_name=$2

    if curl -s -f "$url/health" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ $service_name is running${NC}"
        return 0
    else
        echo -e "${RED}❌ $service_name is not running${NC}"
        return 1
    fi
}

# Function to wait for service to be ready
wait_for_service() {
    local url=$1
    local service_name=$2
    local max_attempts=30
    local attempt=1

    echo -e "${YELLOW}⏳ Waiting for $service_name to be ready...${NC}"

    while [ $attempt -le $max_attempts ]; do
        if curl -s -f "$url" > /dev/null 2>&1; then
            echo -e "${GREEN}✅ $service_name is ready!${NC}"
            return 0
        fi

        echo "Attempt $attempt/$max_attempts - waiting for $service_name..."
        sleep 2
        attempt=$((attempt + 1))
    done

    echo -e "${RED}❌ $service_name failed to start after $max_attempts attempts${NC}"
    return 1
}

# Function to wait for DynamoDB Local
wait_for_dynamodb() {
    local max_attempts=30
    local attempt=1

    echo -e "${YELLOW}⏳ Waiting for DynamoDB Local to be ready...${NC}"

    while [ $attempt -le $max_attempts ]; do
        if aws dynamodb list-tables --endpoint-url "$DYNAMODB_ENDPOINT" > /dev/null 2>&1; then
            echo -e "${GREEN}✅ DynamoDB Local is ready!${NC}"
            return 0
        fi

        echo "Attempt $attempt/$max_attempts - waiting for DynamoDB Local..."
        sleep 2
        attempt=$((attempt + 1))
    done

    echo -e "${RED}❌ DynamoDB Local failed to start after $max_attempts attempts${NC}"
    return 1
}

# Step 1: Start Docker Compose services
echo -e "${YELLOW}📦 Starting Docker Compose services...${NC}"
docker compose up -d

# Step 2: Wait for DynamoDB Local to be ready
wait_for_dynamodb

# Step 3: Create DynamoDB table
echo -e "${YELLOW}🗄️  Creating DynamoDB table: $TABLE_NAME${NC}"

# Check if table already exists
if aws dynamodb describe-table --table-name "$TABLE_NAME" --endpoint-url "$DYNAMODB_ENDPOINT" > /dev/null 2>&1; then
    echo -e "${YELLOW}⚠️  Table $TABLE_NAME already exists, skipping creation${NC}"
else
    aws dynamodb create-table \
        --table-name "$TABLE_NAME" \
        --attribute-definitions AttributeName=short_code,AttributeType=S \
        --key-schema AttributeName=short_code,KeyType=HASH \
        --billing-mode PAY_PER_REQUEST \
        --endpoint-url "$DYNAMODB_ENDPOINT" > /dev/null

    echo -e "${GREEN}✅ Table $TABLE_NAME created successfully${NC}"
fi

# Step 4: Wait for microservices to be ready
wait_for_service "$SHORTEN_SERVICE_URL/health" "Shorten Service"
wait_for_service "$REDIRECT_SERVICE_URL/health" "Redirect Service"

# Step 5: Verify all services are healthy
echo -e "${YELLOW}🔍 Verifying all services...${NC}"

check_service "$SHORTEN_SERVICE_URL" "Shorten Service"
check_service "$REDIRECT_SERVICE_URL" "Redirect Service"

# Step 6: Display service information
echo -e "${GREEN}🎉 Local development environment is ready!${NC}"
echo ""
echo -e "${YELLOW}📋 Service URLs:${NC}"
echo "  • Shorten Service: $SHORTEN_SERVICE_URL"
echo "  • Redirect Service: $REDIRECT_SERVICE_URL"
echo "  • DynamoDB Local: $DYNAMODB_ENDPOINT"
echo ""
echo -e "${YELLOW}🧪 Test commands:${NC}"
echo "  • Health check: curl $SHORTEN_SERVICE_URL/health"
echo "  • Create short URL: curl -X POST $SHORTEN_SERVICE_URL/shorten -H 'Content-Type: application/json' -d '{\"url\":\"https://example.com\"}'"
echo "  • List tables: aws dynamodb list-tables --endpoint-url $DYNAMODB_ENDPOINT"
echo ""
echo -e "${YELLOW}🛑 To stop services:${NC}"
echo "  docker compose down"
