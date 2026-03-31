# Multi-Agent SDLC Kubernetes Manifests

This directory contains Kubernetes manifests for deploying the Multi-Agent SDLC system components:

- API server
- Orchestrator agent
- Coding agent
- Testing agent
- Review agent
- Docs agent
- GitOps agent
- Redis

The manifests expect these images:

- `satish27072002/multi-agent-sdlc-api:latest`
- `satish27072002/multi-agent-sdlc-orchestrator:latest`
- `satish27072002/multi-agent-sdlc-coding:latest`
- `satish27072002/multi-agent-sdlc-testing:latest`
- `satish27072002/multi-agent-sdlc-review:latest`
- `satish27072002/multi-agent-sdlc-docs:latest`
- `satish27072002/multi-agent-sdlc-gitops:latest`

Create secret before deploy:

```bash
kubectl create secret generic multi-agent-secrets \
  -n multi-agent \
  --from-literal=GROQ_API_KEY="<your-key>"
```

Apply all resources:

```bash
kubectl apply -k kubernetes/apps/multi-agent
```
