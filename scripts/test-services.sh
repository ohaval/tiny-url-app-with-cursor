#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SHORTEN_SERVICE_URL="http://localhost:8000"
REDIRECT_SERVICE_URL="http://localhost:8001"
DYNAMODB_ENDPOINT="http://localhost:8002"

echo -e "${GREEN}🧪 Testing tiny-url containerized services${NC}"

# Function to run a test
run_test() {
    local test_name=$1
    local command=$2
    local expected_status=$3

    echo -e "${BLUE}🔍 Test: $test_name${NC}"

    # Run the command and capture both output and status code
    response=$(eval "$command" 2>&1)
    status_code=$?

    if [ $status_code -eq $expected_status ]; then
        echo -e "${GREEN}✅ PASS${NC}"
        echo "Response: $response"
    else
        echo -e "${RED}❌ FAIL${NC}"
        echo "Expected status: $expected_status, Got: $status_code"
        echo "Response: $response"
    fi
    echo ""
}

# Function to extract short code from response
extract_short_code() {
    local response=$1
    echo "$response" | grep -o '"short_url":"[^"]*"' | cut -d'"' -f4 | sed 's|.*/||'
}

echo -e "${YELLOW}📋 Running service tests...${NC}"
echo ""

# Test 1: Health checks
run_test "Shorten service health check" \
    "curl -s -f $SHORTEN_SERVICE_URL/health" \
    0

run_test "Redirect service health check" \
    "curl -s -f $REDIRECT_SERVICE_URL/health" \
    0

# Test 2: Service info endpoints
run_test "Shorten service info" \
    "curl -s -f $SHORTEN_SERVICE_URL/" \
    0

run_test "Redirect service info" \
    "curl -s -f $REDIRECT_SERVICE_URL/" \
    0

# Test 3: Create a short URL
echo -e "${BLUE}🔍 Test: Create short URL${NC}"
create_response=$(curl -s -X POST $SHORTEN_SERVICE_URL/shorten \
    -H 'Content-Type: application/json' \
    -d '{"url":"https://example.com/test"}')

if echo "$create_response" | grep -q "short_url"; then
    echo -e "${GREEN}✅ PASS${NC}"
    echo "Response: $create_response"

    # Extract short code for redirect test
    short_code=$(extract_short_code "$create_response")
    echo "Extracted short code: $short_code"
else
    echo -e "${RED}❌ FAIL${NC}"
    echo "Response: $create_response"
fi
echo ""

# Test 4: Test redirect (if we got a short code)
if [ ! -z "$short_code" ]; then
    echo -e "${BLUE}🔍 Test: Redirect to original URL${NC}"
    redirect_response=$(curl -s -I $REDIRECT_SERVICE_URL/$short_code)

    if echo "$redirect_response" | grep -q "HTTP/1.1 302"; then
        echo -e "${GREEN}✅ PASS${NC}"
        echo "Got 302 redirect as expected"
        location=$(echo "$redirect_response" | grep -i "location:" | cut -d' ' -f2- | tr -d '\r')
        echo "Redirect location: $location"
    else
        echo -e "${RED}❌ FAIL${NC}"
        echo "Expected 302 redirect, got:"
        echo "$redirect_response"
    fi
    echo ""
fi

# Test 5: Create custom short URL
echo -e "${BLUE}🔍 Test: Create custom short URL${NC}"
custom_response=$(curl -s -X POST $SHORTEN_SERVICE_URL/shorten \
    -H 'Content-Type: application/json' \
    -d '{"url":"https://example.com/custom", "custom_code":"test123"}')

if echo "$custom_response" | grep -q "test123"; then
    echo -e "${GREEN}✅ PASS${NC}"
    echo "Response: $custom_response"
else
    echo -e "${RED}❌ FAIL${NC}"
    echo "Response: $custom_response"
fi
echo ""

# Test 6: Test custom redirect
echo -e "${BLUE}🔍 Test: Redirect custom short URL${NC}"
custom_redirect_response=$(curl -s -I $REDIRECT_SERVICE_URL/test123)

if echo "$custom_redirect_response" | grep -q "HTTP/1.1 302"; then
    echo -e "${GREEN}✅ PASS${NC}"
    echo "Got 302 redirect as expected"
    location=$(echo "$custom_redirect_response" | grep -i "location:" | cut -d' ' -f2- | tr -d '\r')
    echo "Redirect location: $location"
else
    echo -e "${RED}❌ FAIL${NC}"
    echo "Expected 302 redirect, got:"
    echo "$custom_redirect_response"
fi
echo ""

# Test 7: Test invalid URL
run_test "Invalid URL handling" \
    "curl -s -X POST $SHORTEN_SERVICE_URL/shorten -H 'Content-Type: application/json' -d '{\"url\":\"not-a-url\"}' | grep -q error" \
    0

# Test 8: Test non-existent short code
run_test "Non-existent short code" \
    "curl -s $REDIRECT_SERVICE_URL/nonexistent | grep -q error" \
    0

# Test 9: DynamoDB table check
run_test "DynamoDB table exists" \
    "aws dynamodb describe-table --table-name url_mappings --endpoint-url $DYNAMODB_ENDPOINT > /dev/null" \
    0

echo -e "${GREEN}🎉 Service testing completed!${NC}"
echo ""
echo -e "${YELLOW}💡 Additional manual tests you can run:${NC}"
echo "  • Load test: ab -n 100 -c 10 $SHORTEN_SERVICE_URL/health"
echo "  • View DynamoDB items: aws dynamodb scan --table-name url_mappings --endpoint-url $DYNAMODB_ENDPOINT"
echo "  • Monitor logs: docker-compose logs -f shorten"
