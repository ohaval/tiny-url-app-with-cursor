#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
CLUSTER_NAME="tiny-url-local"
NAMESPACE="tiny-url"

echo -e "${GREEN}🚀 Setting up local Kubernetes environment for tiny-url-app${NC}"
echo ""

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to wait for deployment to be ready
wait_for_deployment() {
    local deployment=$1
    local namespace=$2
    local timeout=${3:-120}

    echo -e "${YELLOW}⏳ Waiting for $deployment to be ready...${NC}"
    if kubectl wait --for=condition=available --timeout=${timeout}s deployment/$deployment -n $namespace >/dev/null 2>&1; then
        echo -e "${GREEN}✅ $deployment is ready!${NC}"
        return 0
    else
        echo -e "${RED}❌ $deployment failed to become ready within ${timeout}s${NC}"
        return 1
    fi
}

# Function to wait for job completion
wait_for_job() {
    local job=$1
    local namespace=$2
    local timeout=${3:-120}

    echo -e "${YELLOW}⏳ Waiting for job $job to complete...${NC}"
    if kubectl wait --for=condition=complete --timeout=${timeout}s job/$job -n $namespace >/dev/null 2>&1; then
        echo -e "${GREEN}✅ Job $job completed successfully!${NC}"
        return 0
    else
        echo -e "${RED}❌ Job $job failed to complete within ${timeout}s${NC}"
        return 1
    fi
}

# Check prerequisites
echo -e "${BLUE}🔍 Checking prerequisites...${NC}"

if ! command_exists kubectl; then
    echo -e "${RED}❌ kubectl not found. Please install it first.${NC}"
    exit 1
fi

if ! command_exists kind; then
    echo -e "${RED}❌ kind not found. Please install it first.${NC}"
    exit 1
fi

if ! command_exists docker; then
    echo -e "${RED}❌ Docker not found. Please install it first.${NC}"
    exit 1
fi

echo -e "${GREEN}✅ All prerequisites found${NC}"

# Check if cluster exists
echo -e "${BLUE}🔍 Checking for existing kind cluster...${NC}"
if kind get clusters | grep -q "^${CLUSTER_NAME}$"; then
    echo -e "${YELLOW}⚠️  Cluster '${CLUSTER_NAME}' already exists${NC}"
    echo -e "${YELLOW}   Using existing cluster${NC}"
else
    echo -e "${BLUE}🏗️  Creating kind cluster: ${CLUSTER_NAME}${NC}"
    kind create cluster --name $CLUSTER_NAME
    echo -e "${GREEN}✅ Cluster created successfully${NC}"
fi

# Ensure kubectl is using the right context
echo -e "${BLUE}🔧 Setting kubectl context...${NC}"
kubectl config use-context kind-$CLUSTER_NAME >/dev/null
echo -e "${GREEN}✅ kubectl context set to kind-${CLUSTER_NAME}${NC}"

# Build Docker images if they don't exist
echo -e "${BLUE}🏗️  Building Docker images...${NC}"
if ! docker images | grep -q "tiny-url-shorten.*local"; then
    echo -e "${YELLOW}📦 Building shorten service image...${NC}"
    docker build -f docker/shorten/Dockerfile -t tiny-url-shorten:local . >/dev/null
fi

if ! docker images | grep -q "tiny-url-redirect.*local"; then
    echo -e "${YELLOW}📦 Building redirect service image...${NC}"
    docker build -f docker/redirect/Dockerfile -t tiny-url-redirect:local . >/dev/null
fi

echo -e "${GREEN}✅ Docker images ready${NC}"

# Load images into kind cluster
echo -e "${BLUE}📥 Loading images into kind cluster...${NC}"
kind load docker-image tiny-url-shorten:local --name $CLUSTER_NAME >/dev/null
kind load docker-image tiny-url-redirect:local --name $CLUSTER_NAME >/dev/null
echo -e "${GREEN}✅ Images loaded into cluster${NC}"

# Apply Kubernetes manifests in dependency order
echo -e "${BLUE}🚀 Deploying Kubernetes resources...${NC}"

# 1. Namespace
echo -e "${YELLOW}📁 Creating namespace...${NC}"
kubectl apply -f k8s/local/namespace.yaml >/dev/null
echo -e "${GREEN}✅ Namespace created${NC}"

# 2. Database layer
echo -e "${YELLOW}🗄️  Deploying database layer...${NC}"
kubectl apply -f k8s/local/dynamodb/ >/dev/null
wait_for_deployment dynamodb $NAMESPACE

# 3. Wait for DynamoDB to fully initialize
echo -e "${YELLOW}⏱️  Allowing DynamoDB to fully initialize (20 seconds)...${NC}"
sleep 20
echo -e "${GREEN}✅ DynamoDB should be ready for connections${NC}"

# 3. Initialize database
echo -e "${YELLOW}🔧 Initializing database...${NC}"
# Delete existing job if it exists (jobs can't be updated)
kubectl delete job dynamodb-init -n $NAMESPACE >/dev/null 2>&1 || true
kubectl apply -f k8s/local/dynamodb/init-job.yaml >/dev/null
wait_for_job dynamodb-init $NAMESPACE

# 4. Application services
echo -e "${YELLOW}🔄 Deploying application services...${NC}"
kubectl apply -f k8s/local/shorten/ >/dev/null
kubectl apply -f k8s/local/redirect/ >/dev/null

wait_for_deployment shorten $NAMESPACE
wait_for_deployment redirect $NAMESPACE

# Verify deployment
echo -e "${BLUE}🔍 Verifying deployment...${NC}"
echo ""

# Show cluster status
echo -e "${YELLOW}📊 Cluster Status:${NC}"
kubectl get pods -n $NAMESPACE

echo ""
echo -e "${YELLOW}🌐 Services:${NC}"
kubectl get services -n $NAMESPACE

echo ""

# Test the services
echo -e "${BLUE}🧪 Testing services...${NC}"

# Test shorten service health
if kubectl run test-pod --image=curlimages/curl:latest --rm -it --restart=Never -n $NAMESPACE -- curl -s http://shorten-service:8000/health >/dev/null 2>&1; then
    echo -e "${GREEN}✅ Shorten service is healthy${NC}"
else
    echo -e "${RED}❌ Shorten service health check failed${NC}"
fi

# Test redirect service health
if kubectl run test-pod --image=curlimages/curl:latest --rm -it --restart=Never -n $NAMESPACE -- curl -s http://redirect-service:8001/health >/dev/null 2>&1; then
    echo -e "${GREEN}✅ Redirect service is healthy${NC}"
else
    echo -e "${RED}❌ Redirect service health check failed${NC}"
fi

echo ""
echo -e "${GREEN}🎉 Local Kubernetes environment is ready!${NC}"
echo ""
echo -e "${YELLOW}📋 Quick Info:${NC}"
echo "  • Cluster: $CLUSTER_NAME"
echo "  • Namespace: $NAMESPACE"
echo "  • Context: kind-$CLUSTER_NAME"
echo ""
echo -e "${YELLOW}🧪 Test commands:${NC}"
echo "  • List pods: kubectl get pods -n $NAMESPACE"
echo "  • View logs: kubectl logs -f deployment/shorten -n $NAMESPACE"
echo "  • Test API: kubectl run test-pod --image=curlimages/curl:latest --rm -it --restart=Never -n $NAMESPACE -- curl -X POST http://shorten-service:8000/shorten -H 'Content-Type: application/json' -d '{\"url\":\"https://example.com\"}'"
echo ""
echo -e "${YELLOW}🛑 To cleanup:${NC}"
echo "  • Remove resources: make k8s-down"
echo "  • Remove cluster: make k8s-clean"
