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

echo -e "${RED}💥 Destroying local Kubernetes cluster completely${NC}"
echo ""

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check prerequisites
if ! command_exists kind; then
    echo -e "${RED}❌ kind not found. Cannot destroy cluster.${NC}"
    exit 1
fi

# Check if cluster exists
echo -e "${BLUE}🔍 Checking for kind cluster...${NC}"
if ! kind get clusters | grep -q "^${CLUSTER_NAME}$"; then
    echo -e "${YELLOW}⚠️  Cluster '${CLUSTER_NAME}' not found${NC}"
    echo -e "${GREEN}✅ Nothing to destroy${NC}"
    exit 0
fi

# Show cluster info before destruction
echo -e "${BLUE}📊 Cluster to be destroyed:${NC}"
echo "  • Name: $CLUSTER_NAME"
echo "  • Context: kind-$CLUSTER_NAME"
echo ""

# Destroy the cluster
echo -e "${RED}💥 Destroying kind cluster '$CLUSTER_NAME'...${NC}"
kind delete cluster --name $CLUSTER_NAME

echo ""
echo -e "${GREEN}🎉 Kubernetes cluster destroyed completely!${NC}"
echo ""
echo -e "${YELLOW}📋 What was destroyed:${NC}"
echo "  • Kind cluster: $CLUSTER_NAME"
echo "  • All namespaces and resources"
echo "  • Kubernetes context: kind-$CLUSTER_NAME"
echo "  • All persistent data"
echo ""
echo -e "${YELLOW}💡 Note:${NC}"
echo "  • Docker images are still available for reuse"
echo "  • kubectl context removed automatically"
echo ""
echo -e "${YELLOW}🚀 To recreate everything:${NC}"
echo "  • Run: make k8s-setup"
