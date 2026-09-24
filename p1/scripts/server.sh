#!/usr/bin/env bash
set -euo pipefail

apt-get update -qq
apt-get install -y -qq curl net-tools

IFACE=$(ip -o -4 addr show | awk -v ip="$NODE_IP" '$4 ~ "^"ip"/" {print $2}')

curl -sfL https://get.k3s.io | K3S_TOKEN="$K3S_TOKEN" sh -s - server \
  --node-ip "$NODE_IP" \
  --advertise-address "$NODE_IP" \
  --flannel-iface "$IFACE" \
  --write-kubeconfig-mode 644

echo "alias k=kubectl" >> /home/vagrant/.bashrc