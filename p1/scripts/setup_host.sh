#!/usr/bin/env bash
# Installs Vagrant + VirtualBox on the host (Mac, or the school Linux host VM)
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
    command -v brew >/dev/null || { echo "Install Homebrew first please"; exit 1; }
    brew install --cask vagrant
    command -v VBoxManage >/dev/null || brew install --cask virtualbox
    echo "==> Done. Run: vagrant up"
    exit 0
fi

if [ "$ARCH" = arm64 ]; then
    echo "HashiCorp ships Vagrant for Linux amd64 only."
    echo "On an ARM Linux VM, run parts 1-2 from macOS instead."
    exit 1
fi

# Linux amd64 (school host VM): VirtualBox needs nested virtualization here
if [ "$(grep -cE 'vmx|svm' /proc/cpuinfo)" -eq 0 ]; then
    echo "No VT-x/AMD-V in this VM: power it off and tick"
    echo "Settings > System > Processor > Enable Nested VT-x/AMD-V"
    exit 1
fi

sudo apt-get update
sudo apt-get install -y curl gpg lsb-release build-essential "linux-headers-$(uname -r)"

# Vagrant from HashiCorp's repo (Debian's own package is too old)
curl -fsSL https://apt.releases.hashicorp.com/gpg \
    | sudo gpg --dearmor --yes -o /usr/share/keyrings/hashicorp.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" \
    | sudo tee /etc/apt/sources.list.d/hashicorp.list >/dev/null

# VirtualBox from Oracle's repo
curl -fsSL https://www.virtualbox.org/download/oracle_vbox_2016.asc \
    | sudo gpg --dearmor --yes -o /usr/share/keyrings/virtualbox.gpg
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/virtualbox.gpg] https://download.virtualbox.org/virtualbox/debian $(lsb_release -cs) contrib" \
    | sudo tee /etc/apt/sources.list.d/virtualbox.list >/dev/null

sudo apt-get update
# Newest virtualbox-X.Y package available, so the script keeps working after an update
VBOX_PKG=$(apt-cache search --names-only '^virtualbox-[0-9.]+$' | awk '{print $1}' | sort -V | tail -1)
sudo apt-get install -y vagrant "$VBOX_PKG"
sudo usermod -aG vboxusers "$USER"

echo "==> Done. Log out and back in (vboxusers group), then: vagrant up"
