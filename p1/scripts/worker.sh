#!/usr/bin/env bash
set -euo pipefail
IFACE=$(ip -o -4 addr show | awk -v ip="$NODE_IP" '$4 ~ "^"ip"/" {print $2}')

# Wait for server's API port answers
until (echo > "/dev/tcp/$SERVER_IP/6443") 2>/dev/null; do
  echo "waiting for K3s server..."; sleep 5
done

curl -sfL https://get.k3s.io | \
  K3S_URL="https://$SERVER_IP:6443" K3S_TOKEN="$K3S_TOKEN" sh -s - agent \
  --node-ip "$NODE_IP" \
  --flannel-iface "$IFACE"