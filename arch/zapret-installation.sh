#!/bin/bash

# Defines configs' path

CONFIG_PATH="$HOME/zapretconfigs"

# Stops the script if an error occurs
set -e

# Checks sudo
sudo -v || { echo "sudo privileges are required"; exit 1; }

# Checks if curl is installed
if ! command -v curl >/dev/null; then
    echo "curl not found, installing..."
    yay -S --noconfirm curl || { echo "curl could not be installed"; exit 1; }
fi

# Checks does yay exist
command -v yay >/dev/null || { echo "yay needed"; exit 1; }

# Checks if zapret and dnscrypt are already installed

if [ -d "/opt/zapret" ]; then
    echo "zapret is already installed."
else
    echo "zapret is not installed. Installing..."
    yay -S --noconfirm zapret-git
fi

if [ -d "/etc/dnscrypt-proxy" ]; then
    echo "dnscrypt-proxy is already installed."
else
    echo "dnscrypt-proxy is not installed. Installing..."
    yay -S --noconfirm dnscrypt-proxy
fi

# Checks does chattr exist
command -v chattr >/dev/null || { echo "chattr needed"; exit 1; }

# Creates folder for zapret and dnscrypt's config files.

mkdir -p "$CONFIG_PATH"

# Cheks if user clone the repository or not

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GITHUB_RAW="https://raw.githubusercontent.com/ZaferOrucoglu/zapret-installation/main/arch/"

if [ -f "$SCRIPT_DIR/config" ]; then
    cp "$SCRIPT_DIR/config" "$CONFIG_PATH/"
else
    curl -fL "$GITHUB_RAW/config" -o "$CONFIG_PATH/config"
fi

if [ -f "$SCRIPT_DIR/dnscrypt-proxy.toml" ]; then
    cp "$SCRIPT_DIR/dnscrypt-proxy.toml" "$CONFIG_PATH/"
else
    curl -fL "$GITHUB_RAW/dnscrypt-proxy.toml" -o "$CONFIG_PATH/dnscrypt-proxy.toml"
fi

# Copies dnscrypt-proxy and zapret configuration files
sudo cp "$CONFIG_PATH/dnscrypt-proxy.toml" /etc/dnscrypt-proxy/
sudo cp "$CONFIG_PATH/config" /opt/zapret/

# Disable systemd-resolved units only if they exist (set -e safe) and enable dnscrypt-proxy
for unit in \
  systemd-resolved-varlink.socket \
  systemd-resolved-monitor.socket \
  systemd-resolved.service
do
  if systemctl list-unit-files --type=service --type=socket --all | awk '{print $1}' | grep -qx "$unit"; then
    sudo systemctl disable --now "$unit"
  else
    echo "Skipping $unit (not found on this system)"
  fi
done
sudo systemctl enable --now dnscrypt-proxy

# Setting up dnscrypt-proxy as a DNS resolver
sudo chattr -i /etc/resolv.conf 2>/dev/null || true
sudo install -d -m 755 /etc/NetworkManager/conf.d
printf "[main]\ndns=none\n" | sudo tee /etc/NetworkManager/conf.d/dns.conf >/dev/null
echo "nameserver 127.0.0.1" | sudo tee /etc/resolv.conf >/dev/null
sudo chattr +i /etc/resolv.conf # protects resolv.conf against NetworkManager

sudo systemctl restart dnscrypt-proxy
sudo systemctl restart NetworkManager

echo "the file /etc/resolv.conf will be protected against NetworkManager!"
echo "if you want to make /etc/resolv.conf writable again, run:"
echo "sudo chattr -i /etc/resolv.conf"

# Setting the blacklist of zapret and enable it
echo "Do you want to add websites to the Zapret exclude list?"

while true; do
    read -p "Enter 'y/yes' or 'n/no': " answer
    if [[ "${answer,,}" == "y" || "${answer,,}" == "yes" ]]; then
        # Run initial setup once
        sudo bash /opt/zapret/ipset/get_exclude.sh

        # Let user add websites until they type c or cancel
        while true; do
            read -p "Enter website URL (just 1 website each answer, type c or cancel to finish adding): " website
            if [[ "${website,,}" == "c" || "${website,,}" == "cancel" ]]; then
                echo "Finished adding websites."
                break
            elif [[ -z "$website" ]]; then
                echo "Empty input. Please enter a website or 'c'/'cancel' to finish."
                continue
            else
                echo "$website" | sudo tee -a /opt/zapret/ipset/zapret-hosts-user-exclude.txt > /dev/null
                echo "Added!"
            fi
        done
        break
    elif [[ "${answer,,}" == "n" || "${answer,,}" == "no" ]]; then
        echo "Skipping adding websites."
        break
    else
        # handling invalid input
        echo "Invalid input. Please enter 'y/yes' or 'n/no'."
    fi
done

# Enable zapret
sudo systemctl enable --now zapret

# Ask user if they want to remove config files from $CONFIG_PATH
while true; do
    read -p "Do you want to keep config files on $CONFIG_PATH (false by default, type yes/y or no/n)" remove
    if [[ "$remove" == "n" || "$remove" == "no" ]]; then
        rm -rf "$CONFIG_PATH"
        break
    elif [[ "$remove" == "y" || "$remove" == "yes" ]]; then
        break
    else
        echo "Invalid input. Please type 'y/yes' or 'n/no'"
    fi
done

echo "Installation complete"
