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

echo -e "${RED}🧹 Cleaning up local Kubernetes environment${NC}"
echo ""

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check prerequisites
if ! command_exists kubectl; then
    echo -e "${RED}❌ kubectl not found. Cannot cleanup.${NC}"
    exit 1
fi

if ! command_exists kind; then
    echo -e "${RED}❌ kind not found. Cannot cleanup.${NC}"
    exit 1
fi

# Check if cluster exists
echo -e "${BLUE}🔍 Checking for kind cluster...${NC}"
if ! kind get clusters | grep -q "^${CLUSTER_NAME}$"; then
    echo -e "${YELLOW}⚠️  Cluster '${CLUSTER_NAME}' not found${NC}"
    echo -e "${GREEN}✅ Nothing to cleanup${NC}"
    exit 0
fi

# Ensure kubectl is using the right context
echo -e "${BLUE}🔧 Setting kubectl context...${NC}"
kubectl config use-context kind-$CLUSTER_NAME >/dev/null 2>&1 || {
    echo -e "${YELLOW}⚠️  Cannot set context, cluster might be already deleted${NC}"
}

# Show what we're about to delete
echo -e "${BLUE}📊 Current resources in namespace '$NAMESPACE':${NC}"
if kubectl get namespace $NAMESPACE >/dev/null 2>&1; then
    kubectl get all -n $NAMESPACE 2>/dev/null || echo "No resources found"
    echo ""

    # Delete namespace (this deletes everything in it)
    echo -e "${RED}🗑️  Deleting namespace '$NAMESPACE' and all resources...${NC}"
    kubectl delete namespace $NAMESPACE --ignore-not-found=true >/dev/null 2>&1

    # Wait for namespace to be fully deleted
    echo -e "${YELLOW}⏳ Waiting for namespace to be fully deleted...${NC}"
    while kubectl get namespace $NAMESPACE >/dev/null 2>&1; do
        sleep 1
    done

    echo -e "${GREEN}✅ Namespace and all resources deleted${NC}"
else
    echo -e "${YELLOW}⚠️  Namespace '$NAMESPACE' not found${NC}"
fi

echo ""
echo -e "${GREEN}🎉 Kubernetes resources cleanup completed!${NC}"
echo ""
echo -e "${YELLOW}📋 What was cleaned up:${NC}"
echo "  • Namespace: $NAMESPACE"
echo "  • All pods, services, deployments, configmaps, jobs"
echo "  • Application data (DynamoDB tables, etc.)"
echo ""
echo -e "${YELLOW}💡 Note:${NC}"
echo "  • Kind cluster '$CLUSTER_NAME' is still running"
echo "  • Docker images are still available"
echo "  • To also delete the cluster: make k8s-clean"
echo ""
echo -e "${YELLOW}🚀 To redeploy:${NC}"
echo "  • Run: make k8s-setup"
