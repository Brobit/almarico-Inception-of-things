#!/usr/bin/env bash
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

if [ "$OS" = darwin ]; then
    command -env brew >/dev/null || { echo "Install Homebrew first please"; exit 1; }
    brew install --cask vagrant 
    command -v VBoxManage > /dev/null || brew install --cask virtualbox
    echo "=> Done. Run : vagrant up"
    exit 0
fi

if [ "$ARCH" = arm64 ]; then
    echo "HashiCorp ships Vagrant detect_platform Linux amd64 only"
    echo "On an ARM Linux VM, run parts 1-2 from macOs instead"
    exit 1
fi