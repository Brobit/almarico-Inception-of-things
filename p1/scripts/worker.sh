#!/usr/bin/env bash
set -euo pipefail

apt-get update -qq
apt-get install -y -qq curl net-tools

IFACE=$(ip -o -4 addr show | awk -v ip="$NODE_IP" '$4 ~ "^"ip"/" {print $2}')

until (echo > "/dev/tcp/$SERVER_IP/6443") 2>/dev/null; do
  echo "En attente du server K3s..."
  sleep 5
done

curl -sfL https://get.k3s.io | \
  K3S_URL="https://$SERVER_IP:6443" K3S_TOKEN="$K3S_TOKEN" sh -s - agent \
  --node-ip "$NODE_IP" \
  --flannel-iface "$IFACE"