#!/usr/bin/env bash
# Installs everything Part 3 needs: Docker, kubectl, k3d
# (+ amd64 emulation on ARM, because wil42/playground is amd64 only)
set -euo pipefail

detect_platform() {
    case "$(uname -s)" in
        Linux)  OS=linux ;;
        Darwin) OS=darwin ;;
        *) echo "Unsupported OS: $(uname -s)"; exit 1 ;;
    esac
    case "$(uname -m)" in
        x86_64|amd64)  ARCH=amd64 ;;
        aarch64|arm64) ARCH=arm64 ;;
        *) echo "Unsupported CPU: $(uname -m)"; exit 1 ;;
    esac
    echo "==> Platform: $OS/$ARCH"
}

detect_platform
[ "$OS" = linux ] || { echo "Run this inside the Linux host VM"; exit 1; }

sudo apt-get update
sudo apt-get install -y curl ca-certificates git

# Docker (the official script supports amd64 and arm64)
if ! command -v docker >/dev/null; then
    curl -fsSL https://get.docker.com | sudo sh
fi
sudo usermod -aG docker "$USER"

# kubectl for this CPU
KVER=$(curl -fsSL https://dl.k8s.io/release/stable.txt)
curl -fsSLo /tmp/kubectl "https://dl.k8s.io/release/${KVER}/bin/linux/${ARCH}/kubectl"
sudo install -m 0755 /tmp/kubectl /usr/local/bin/kubectl

# k3d (its installer detects the CPU itself)
curl -fsSL https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash

# ARM only: run amd64 images through QEMU. The Debian package registers it
# at every boot, so it survives a reboot of the VM.
if [ "$ARCH" = arm64 ]; then
    sudo apt-get install -y qemu-user-binfmt
fi

echo "==> Done. Log out and back in (docker group), then run setup.sh"
