#!/usr/bin/env bash
# Creates the k3d cluster, the argocd + dev namespaces, installs Argo CD
# and registers the application that Argo CD deploys from GitHub
set -euo pipefail
DIR="$(cd "$(dirname "$0")/.." && pwd)"
CLUSTER=iot

# Port 8888 of the VM goes to the k3d load balancer, then to the app's Service
if ! k3d cluster get "$CLUSTER" >/dev/null 2>&1; then
    k3d cluster create "$CLUSTER" -p "8888:8888@loadbalancer" --wait
fi

for ns in argocd dev; do
    kubectl create namespace "$ns" --dry-run=client -o yaml | kubectl apply -f -
done

# --server-side: some Argo CD CRDs are too big for a normal apply
kubectl apply -n argocd --server-side --force-conflicts \
    -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl -n argocd rollout status deploy/argocd-server --timeout=300s
kubectl -n argocd rollout status statefulset/argocd-application-controller --timeout=300s

kubectl apply -f "$DIR/confs/application.yaml"

echo "==> Argo CD admin password:"
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d; echo
echo "==> UI:  kubectl -n argocd port-forward svc/argocd-server 8080:443   then open https://localhost:8080 (user: admin)"
echo "==> App: curl http://localhost:8888/"
