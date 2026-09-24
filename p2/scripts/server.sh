#!/usr/bin/env bash
set -euo pipefail

apt-get update -qq
apt-get install -y -qq curl net-tools

IFACE=$(ip -o -4 addr show | awk -v ip="$NODE_IP" '$4 ~ "^"ip"/" {print $2}')

curl -sfL https://get.k3s.io | sh -s - server \
  --node-ip "$NODE_IP" \
  --flannel-iface "$IFACE" \
  --write-kubeconfig-mode 644

until kubectl get nodes 2>/dev/null | grep -q " Ready"; do
  echo "En attente du nœud..."
  sleep 3
done

kubectl apply -f /tmp/confs/
echo "alias k=kubectl" >> /home/vagrant/.bashrc