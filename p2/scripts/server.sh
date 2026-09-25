#!/usr/bin/env bash
set -euo pipefail

# Find the interface that carries 192.168.56.x (eth1)
IFACE=$(ip -o -4 addr show | awk -v ip="$NODE_IP" '$4 ~ "^"ip"/" {print $2}')

curl -sfL https://get.k3s.io | sh -s - server \
    --node-ip "$NODE_IP" \
    --flannel-iface "$IFACE" \
    --write-kubeconfig-mode 644

# The node takes a few seconds to register: wait for it to exist, then to be Ready
until kubectl get nodes -o name 2>/dev/null | grep -q .; do
    echo "waiting for the node to register..."; sleep 3
done
kubectl wait --for=condition=Ready node --all --timeout=180s

# -R: a re-provision copies confs/ inside the existing /tmp/confs, apply handles both
kubectl apply -R -f /tmp/confs/

# Traefik (the Ingress controller) is installed by a K3s Helm job a bit later: wait for it
until kubectl -n kube-system get deploy traefik >/dev/null 2>&1; do
    echo "waiting for Traefik to be installed..."; sleep 3
done
kubectl -n kube-system rollout status deploy/traefik --timeout=300s
kubectl wait --for=condition=Available deploy --all --timeout=180s

grep -q "alias k=kubectl" /home/vagrant/.bashrc || echo "alias k=kubectl" >> /home/vagrant/.bashrc
