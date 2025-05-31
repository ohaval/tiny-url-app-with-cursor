# Kubernetes & EKS Learning Plan

## Overview
This document outlines a structured approach to learning Kubernetes and Amazon EKS by migrating our tiny URL application from AWS Lambda/CDK to a containerized Kubernetes deployment.

## Why This App is Perfect for K8s Learning

### Advantages
- **Simple but Real** - Not a toy example, but manageable complexity
- **Stateful Components** - Learn about databases, persistent storage, and state management
- **Multiple Services** - URL shortener + redirector = microservices patterns
- **Real Traffic Patterns** - Different read/write ratios teach scaling concepts
- **AWS Integration** - Perfect bridge from existing CDK knowledge to EKS

### Current Architecture (Lambda/CDK)
- **Shorten Service**: POST /shorten endpoint
- **Redirect Service**: GET /{short_code} endpoint
- **Database**: DynamoDB
- **Infrastructure**: AWS CDK

### Target Architecture (Kubernetes)
- **Shorten Service**: Containerized microservice
- **Redirect Service**: Containerized microservice
- **Database**: DynamoDB (initially) → PostgreSQL on K8s (later)
- **Infrastructure**: EKS cluster with CDK

## Learning Phases

### Phase 1: Containerization (Week 1)
**Goal**: Transform Lambda functions into containerized microservices

#### Tasks
- [ ] Create Dockerfile for shorten service
- [ ] Create Dockerfile for redirect service
- [ ] Set up docker-compose for local development
- [ ] Test services locally with Docker
- [ ] Learn Docker networking between services

#### Key Concepts to Learn
- Docker fundamentals (images, containers, layers)
- Multi-stage builds for Python applications
- Container networking
- Environment variable management
- Health checks

#### Deliverables
- `docker/shorten/Dockerfile`
- `docker/redirect/Dockerfile`
- `docker-compose.yml`
- Updated README with Docker instructions

### Phase 2: Local Kubernetes (Week 2)
**Goal**: Deploy application to local Kubernetes cluster

#### Tasks
- [ ] Install minikube or kind
- [ ] Create Kubernetes manifests for services
- [ ] Deploy to local cluster
- [ ] Learn kubectl commands
- [ ] Set up local development workflow

#### Key Concepts to Learn
- **Core Objects**:
  - Pods (smallest deployable units)
  - Services (internal networking)
  - Deployments (managing replicas)
  - ConfigMaps (configuration)
  - Secrets (sensitive data)
- **Networking**: ClusterIP, NodePort, LoadBalancer
- **Storage**: Volumes, PersistentVolumes
- **kubectl**: Essential commands and debugging

#### Deliverables
- `k8s/local/` directory with manifests
- Local deployment documentation
- kubectl cheat sheet

### Phase 3: EKS Deployment (Week 3-4)
**Goal**: Deploy application to production EKS cluster

#### Tasks
- [ ] Create EKS cluster with CDK
- [ ] Set up AWS Load Balancer Controller
- [ ] Deploy application to EKS
- [ ] Configure ingress for external access
- [ ] Implement proper secrets management
- [ ] Set up monitoring and logging

#### Key Concepts to Learn
- **EKS Specifics**:
  - ALB Ingress Controller
  - IAM Roles for Service Accounts (IRSA)
  - VPC networking
  - EBS/EFS storage classes
- **Security**: Pod security standards, network policies
- **Observability**: CloudWatch integration, Prometheus/Grafana

#### Deliverables
- `lib/eks-stack.ts` (CDK stack for EKS)
- `k8s/production/` directory with manifests
- Monitoring and alerting setup
- Production deployment guide

### Phase 4: Advanced Concepts (Week 5+)
**Goal**: Implement production-ready Kubernetes patterns

#### Tasks
- [ ] Horizontal Pod Autoscaling (HPA)
- [ ] Vertical Pod Autoscaling (VPA)
- [ ] Service mesh implementation (Istio)
- [ ] GitOps with ArgoCD
- [ ] Blue/green deployments
- [ ] Canary deployments
- [ ] Disaster recovery procedures

#### Key Concepts to Learn
- **Scaling**: HPA, VPA, Cluster Autoscaler
- **Service Mesh**: Traffic management, security, observability
- **GitOps**: Declarative deployments, continuous delivery
- **Advanced Deployments**: Rolling updates, blue/green, canary
- **Reliability**: Circuit breakers, retries, timeouts

#### Deliverables
- Autoscaling configurations
- Service mesh setup
- GitOps pipeline
- Deployment strategies documentation

## Core Kubernetes Concepts Reference

### Essential Objects
| Object | Purpose | Example Use Case |
|--------|---------|------------------|
| Pod | Smallest deployable unit | Single container or tightly coupled containers |
| Service | Internal networking | Expose pods to other services |
| Deployment | Manage pod replicas | Ensure desired number of pods running |
| ConfigMap | Configuration data | Environment variables, config files |
| Secret | Sensitive data | Database passwords, API keys |
| Ingress | External access | Route external traffic to services |

### kubectl Commands Cheat Sheet
```bash
# Cluster info
kubectl cluster-info
kubectl get nodes

# Workloads
kubectl get pods
kubectl get deployments
kubectl get services

# Debugging
kubectl describe pod <pod-name>
kubectl logs <pod-name>
kubectl exec -it <pod-name> -- /bin/bash

# Apply manifests
kubectl apply -f <file.yaml>
kubectl apply -f <directory>/

# Port forwarding
kubectl port-forward service/<service-name> 8080:80
```

## Progress Tracking

### Phase 1: Containerization
- [ ] Docker fundamentals understood
- [ ] Services containerized
- [ ] Local testing successful
- [ ] Documentation updated

### Phase 2: Local Kubernetes
- [ ] Local cluster running
- [ ] Application deployed locally
- [ ] kubectl proficiency achieved
- [ ] Core concepts mastered

### Phase 3: EKS Deployment
- [ ] EKS cluster created
- [ ] Application running in production
- [ ] Monitoring implemented
- [ ] Security configured

### Phase 4: Advanced Concepts
- [ ] Autoscaling implemented
- [ ] Service mesh deployed
- [ ] GitOps pipeline active
- [ ] Advanced deployment strategies tested

## Resources and References

### Documentation
- [Kubernetes Official Docs](https://kubernetes.io/docs/)
- [EKS User Guide](https://docs.aws.amazon.com/eks/latest/userguide/)
- [kubectl Reference](https://kubernetes.io/docs/reference/kubectl/)

### Tools
- **Local Development**: minikube, kind, Docker Desktop
- **CLI Tools**: kubectl, helm, eksctl
- **Monitoring**: Prometheus, Grafana, CloudWatch
- **Service Mesh**: Istio, Linkerd

### Learning Resources
- [Kubernetes the Hard Way](https://github.com/kelseyhightower/kubernetes-the-hard-way)
- [EKS Workshop](https://www.eksworkshop.com/)
- [CNCF Landscape](https://landscape.cncf.io/)

## Notes and Learnings
*Use this section to document insights, gotchas, and lessons learned during the journey*

---

**Next Step**: Begin Phase 1 by containerizing the Lambda functions into microservices.
