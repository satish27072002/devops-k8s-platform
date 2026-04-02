# DevOps K8s Platform

A Kubernetes-native CI/CD platform with GitOps automation, Infrastructure as Code, and full observability. Built as production infrastructure for deploying and monitoring microservices — currently serving as the deployment platform for a [Multi-Agent SDLC System](https://github.com/satish27072002/multi-agent-sdlc).

## What this project does

This platform automates the entire deployment lifecycle: push code to Git, and it automatically builds, deploys, and monitors your application on Kubernetes. No manual server management, no SSH, no downtime during updates.

```
Developer pushes code
  → GitHub Actions runs tests and builds container image
    → Image pushed to Docker Hub
      → ArgoCD detects the change
        → Kubernetes rolls out the new version
          → Prometheus collects metrics
            → Grafana displays health dashboards
```

## New laptop quickstart

If the production cluster already exists, you can connect from any new laptop in a few minutes.

**1. Install tools**

```bash
# macOS
brew install git kubectl doctl
```

**2. Authenticate and load kubeconfig**

```bash
export DIGITALOCEAN_ACCESS_TOKEN="<your_do_token>"
doctl auth init --access-token "$DIGITALOCEAN_ACCESS_TOKEN"
doctl kubernetes cluster kubeconfig save 24c3900b-a1cf-455d-aba5-ccb991649468
```

**3. Verify access**

```bash
kubectl get nodes
kubectl get applications -n argocd
kubectl get pods -n monitoring
```

You should see `monitoring-prometheus` and `monitoring-grafana` in `Synced/Healthy` state.

**4. Open Grafana**

```bash
kubectl port-forward service/monitoring-grafana -n monitoring 3000:80
```

Open `http://localhost:3000` and use your existing Grafana admin credentials.

**5. Verify Prometheus remote write (optional)**

```bash
kubectl port-forward service/monitoring-prometheus-server -n monitoring 19090:80
curl -G --data-urlencode 'query=sum(increase(prometheus_remote_storage_samples_total[5m]))' \
  http://127.0.0.1:19090/api/v1/query
curl -G --data-urlencode 'query=sum(increase(prometheus_remote_storage_samples_failed_total[5m]))' \
  http://127.0.0.1:19090/api/v1/query
```

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    Developer Workflow                     │
│                                                          │
│  git push → GitHub repo → ArgoCD syncs → K8s deploys    │
└─────────────────────┬───────────────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────────────┐
│                  Kubernetes Cluster                       │
│                                                          │
│  ┌──────────┐  ┌──────────┐  ┌────────────────────────┐ │
│  │  ArgoCD  │  │ App Pods │  │  Monitoring Stack      │ │
│  │  GitOps  │  │ (your    │  │  Prometheus + Grafana  │ │
│  │  engine  │  │  apps)   │  │  kube-state-metrics    │ │
│  └──────────┘  └──────────┘  └────────────────────────┘ │
│                                                          │
│  Local: k3d (3 nodes)    Production: DigitalOcean DOKS  │
└─────────────────────────────────────────────────────────┘
```

## Tech stack

| Category | Tools |
|----------|-------|
| Container orchestration | Kubernetes (k3d locally, DigitalOcean DOKS in production) |
| GitOps | ArgoCD — auto-deploys from Git to cluster |
| CI/CD | GitHub Actions |
| App packaging | Helm charts with configurable values |
| Infrastructure as Code | Terraform (DigitalOcean provider) |
| Monitoring | Prometheus + Grafana + Grafana Cloud remote write |
| Containerization | Docker (OrbStack on macOS) |
| Cluster management | kubectl, k9s, stern, kubectx |

## Project structure

```
devops-k8s-platform/
├── kubernetes/
│   ├── apps/
│   │   ├── hello-app/              # Sample app (deployment + service)
│   │   └── multi-agent/            # Multi-Agent SDLC app manifests
│   ├── argocd/
│   │   └── applications/           # ArgoCD application definitions
│   └── monitoring/
│       ├── prometheus/
│       └── grafana/
├── helm-charts/
│   └── hello-app/                  # Helm chart with templates + values
│       ├── Chart.yaml
│       ├── values.yaml
│       └── templates/
├── terraform/
│   └── digitalocean/               # IaC for production cluster
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
├── scripts/
└── docs/
```

## What I implemented

**Kubernetes cluster management**
- Multi-node cluster (1 server + 2 agents) using k3d
- Deployed applications with rolling updates and self-healing
- Explored resource management with kubectl and k9s

**GitOps with ArgoCD**
- Installed ArgoCD on the cluster via Helm
- Connected ArgoCD to this GitHub repository
- Configured automated sync — pushing to Git triggers deployment automatically
- Enabled self-healing (cluster reverts manual changes to match Git state)

**Helm charts**
- Created a reusable Helm chart for the hello-app
- Templated deployment and service manifests with configurable values
- Supports different configurations per environment (dev, staging, production)

**Infrastructure as Code**
- Wrote Terraform configurations for a DigitalOcean Kubernetes cluster
- Parameterized with variables: region (ams3), node size, node count, K8s version
- Sensitive values excluded from version control via .gitignore

**Monitoring and observability**
- Deployed Prometheus and Grafana via dedicated ArgoCD applications
- Enabled Prometheus remote write to Grafana Cloud for hosted observability
- Added dashboard-as-code and alert rules for API availability, pod restarts, node readiness, and remote write health

## How to run this locally

**Prerequisites:** macOS with Homebrew, Docker (or OrbStack)

**1. Install tools:**
```bash
brew install kubectl k3d helm k9s stern kubectx
```

**2. Create the cluster:**
```bash
k3d cluster create dev --agents 2 --port "8080:80@loadbalancer"
```

**3. Deploy the sample app:**
```bash
kubectl apply -f kubernetes/apps/hello-app/
kubectl port-forward service/hello-app 9090:80
# Visit http://localhost:9090
```

**4. Install ArgoCD:**
```bash
kubectl create namespace argocd
helm repo add argo https://argoproj.github.io/argo-helm
helm install argocd argo/argo-cd --namespace argocd --wait
```

**5. Install monitoring apps (ArgoCD-managed):**
```bash
kubectl create namespace monitoring
kubectl create namespace argocd
kubectl apply -f kubernetes/argocd/applications/monitoring-prometheus.yaml
kubectl apply -f kubernetes/argocd/applications/monitoring-grafana.yaml

# create Grafana admin secret expected by chart values
kubectl create secret generic monitoring-grafana-admin -n monitoring \
  --from-literal=admin-user=admin \
  --from-literal=admin-password='change-me-now'

kubectl port-forward service/monitoring-grafana -n monitoring 3000:80
# Visit http://localhost:3000
```

**6. Clean up:**
```bash
k3d cluster delete dev
```

## Production deployment

Terraform configurations are ready for DigitalOcean Kubernetes. To deploy:

```bash
cd terraform/digitalocean
terraform init
terraform plan
terraform apply
```

Configuration: 2 worker nodes, s-1vcpu-2gb, Amsterdam (ams3) region. Estimated cost: $24-36/month (covered by DigitalOcean credits).

## What I learned

This was my first Kubernetes project. Key takeaways:

- **Kubernetes is a desired-state system.** You declare what you want in YAML, and K8s figures out how to make it happen. The shift from imperative ("run this") to declarative ("I want this to exist") changes how you think about infrastructure.

- **GitOps eliminates deployment anxiety.** When every change goes through Git, you have a complete audit trail. Rolling back is just reverting a commit. No more "who deployed what and when?"

- **Monitoring isn't optional.** Without Prometheus and Grafana, you're flying blind. With them, you can see exactly what's happening inside your cluster — which pods are struggling, where memory is being consumed, whether deployments are healthy.

- **Infrastructure as Code makes environments reproducible.** Writing Terraform once means anyone can recreate the exact same cluster. No more "it worked on my setup."

- **Self-healing changes your reliability model.** Watching Kubernetes automatically restart crashed pods and maintain replica counts is the moment the value of container orchestration becomes obvious.

## Connected projects

This platform is the infrastructure layer for:

- **[Multi-Agent SDLC System](https://github.com/satish27072002/multi-agent-sdlc)** — A multi-agent AI system that automates the software development lifecycle using MCP and A2A protocols. Each agent (coding, review, gitops) runs as an independent microservice on this Kubernetes platform.

## Author

**Satish Somarouthu**
- GitHub: [@satish27072002](https://github.com/satish27072002)
- Education: Masters at Blekinge Institute of Technology, Sweden
