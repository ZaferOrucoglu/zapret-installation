# zapret-installation

A simple installer script for **Zapret** and **DNSCrypt-Proxy** on **Arch-based Linux (Tested on CachyOS, EndeavourOS, Arch Linux)**, **Debian-based Linux (Tested on PikaOS)**, **Fedora Linux (Tested on Fedora Linux)**, and **Bazzite OS**.

## What this project does

This project helps you install and configure:

- **Zapret** (DPI bypass tool)
- **DNSCrypt-Proxy** (encrypted DNS proxy)

It automates common setup steps so you don't need to do everything manually.

## Supported systems

- Arch Linux
- Arch-based distros (Manjaro, EndeavourOS, etc.)
- Debian / Debian-based distros (Ubuntu, Linux Mint, etc.)
- Fedora Linux
- Bazzite OS

## What the script handles

- Checks `sudo` access
- Verifies required tools (`yay` on Arch, `chattr` on Arch)
- Installs `curl` if missing
- Installs `zapret` and `dnscrypt-proxy` if not installed (`rpm-ostree` layering on Bazzite, requires reboot)
- Enables Terra repo on Bazzite and Fedora (ships disabled, script enables `terra.repo`)
- Uses local config files when available
- Otherwise downloads config files from GitHub raw URLs
- Copies config files to system directories
- Disables `systemd-resolved` units if they exist
- Enables and restarts `dnscrypt-proxy`
- Sets NetworkManager DNS mode to `dns=none`
- Writes `nameserver 127.0.0.1` to `/etc/resolv.conf`
- Protects `/etc/resolv.conf` with `chattr +i` (on Arch Linux)
- Lets you add domains to Zapret exclude list interactively
- Enables Zapret service
- Optionally removes temporary config folder: `$HOME/zapretconfigs`

## Requirements

### Arch

- Arch-based Linux
- `yay`
- `sudo` privileges
- Internet access
- NetworkManager

> `chattr` is usually already present on Arch systems.

### Debian

- Debian-based Linux
- `sudo` privileges
- Internet access
- NetworkManager

### Fedora

- Fedora Linux
- `sudo` privileges
- Internet access
- NetworkManager

> Fedora uses SELinux, so `chattr +i` is intentionally not applied to `/etc/resolv.conf` to avoid conflicts.

### Bazzite

- Bazzite OS
- `sudo` privileges
- Internet access
- NetworkManager

> Bazzite ships Terra disabled. The script enables `/etc/yum.repos.d/terra.repo` and layers packages via `rpm-ostree`, which requires a reboot. Re-run the script after reboot to finish configuration. Like Fedora, `chattr +i` is not used.

## Installation

1. Clone the repository:

```bash
git clone https://github.com/ZaferOrucoglu/zapret-installation.git
cd zapret-installation
```

2. Run the script for your distribution:

**Arch:**
```bash
chmod +x arch/zapret-installation.sh
./arch/zapret-installation.sh
```

**Debian:**
```bash
chmod +x debian/zapret-installation.sh
./debian/zapret-installation.sh
```

**Fedora:**
```bash
chmod +x fedora/zapret-installation.sh
./fedora/zapret-installation.sh
```

**Bazzite:**
```bash
chmod +x bazzite/zapret-installation.sh
./bazzite/zapret-installation.sh
```

> On Bazzite the script layers packages with `rpm-ostree` and exits. Reboot (`systemctl reboot`), then run the script again to apply configs.

3. Follow prompts to:
   - Continue installation flow
   - Add domains to Zapret exclude list (optional)
   - Keep or remove `$HOME/zapretconfigs`

## Important paths

### Arch

- Script: `arch/zapret-installation.sh`
- Zapret config target: `/opt/zapret/config`
- DNSCrypt config target: `/etc/dnscrypt-proxy/dnscrypt-proxy.toml`
- Zapret exclude list: `/opt/zapret/ipset/zapret-hosts-user-exclude.txt`

### Debian

- Script: `debian/zapret-installation.sh`
- Zapret config target: `/opt/zapret/config`
- DNSCrypt config target: `/etc/dnscrypt-proxy/dnscrypt-proxy.toml`
- Zapret exclude list: `/opt/zapret/ipset/zapret-hosts-user-exclude.txt`

### Fedora

- Script: `fedora/zapret-installation.sh`
- Zapret config target: `/etc/zapret/config`
- DNSCrypt config target: `/etc/dnscrypt-proxy/dnscrypt-proxy.toml`
- Zapret exclude list: `/usr/share/zapret/ipset/zapret-hosts-user-exclude.txt`

### Bazzite

- Script: `bazzite/zapret-installation.sh`
- Zapret config target: `/etc/zapret/config`
- DNSCrypt config target: `/etc/dnscrypt-proxy/dnscrypt-proxy.toml`
- Zapret exclude list: `/usr/share/zapret/ipset/zapret-hosts-user-exclude.txt`

### All distributions

- Temporary config dir: `$HOME/zapretconfigs`

## After installation

### Edit DNSCrypt config

**Arch / Debian:**
```bash
sudo nano /etc/dnscrypt-proxy/dnscrypt-proxy.toml
sudo systemctl restart dnscrypt-proxy
```

**Fedora / Bazzite:**
```bash
sudo nano /etc/dnscrypt-proxy/dnscrypt-proxy.toml
sudo systemctl restart dnscrypt-proxy
```

### Add a domain to Zapret exclude list manually

**Arch / Debian:**
```bash
echo "example.com" | sudo tee -a /opt/zapret/ipset/zapret-hosts-user-exclude.txt
sudo systemctl restart zapret
```

**Fedora / Bazzite:**
```bash
echo "example.com" | sudo tee -a /usr/share/zapret/ipset/zapret-hosts-user-exclude.txt
sudo systemctl restart zapret
```

### Make `/etc/resolv.conf` editable again (Arch Linux only)

```bash
sudo chattr -i /etc/resolv.conf
```

If needed, protect it again:

```bash
sudo chattr +i /etc/resolv.conf
```

> This step is only relevant for Arch.

## Troubleshooting

### DNS not working

Restart services:

```bash
sudo systemctl restart dnscrypt-proxy
sudo systemctl restart NetworkManager
```

Check resolver file:

```bash
cat /etc/resolv.conf
```

### Service status checks

```bash
systemctl status dnscrypt-proxy
systemctl status zapret
systemctl status systemd-resolved
```

### Config download issues

If local config files are not found, the script downloads from GitHub raw URLs.
Make sure your internet connection works and GitHub is reachable.

### Fedora: terra repository issues

If zapret cannot be installed, ensure the terra repository is enabled:

```bash
sudo dnf repolist all | grep terra
```

If it is disabled, enable it manually:

```bash
sudo dnf install --nogpgcheck --repofrompath 'terra,https://repos.fyralabs.com/terra$releasever' terra-release
```

### Bazzite: terra repository issues

Bazzite ships Terra disabled. The script enables `/etc/yum.repos.d/terra.repo` automatically. To check manually:

```bash
grep "^enabled" /etc/yum.repos.d/terra.repo
```

To enable manually:

```bash
sudo sed -i 's/^enabled=0/enabled=1/' /etc/yum.repos.d/terra.repo
```

Packages are layered via `rpm-ostree`, so a reboot is required after install. Re-run the script after `systemctl reboot`.

### SELinux on Fedora / Bazzite

If you experience DNS issues and SELinux is enforcing:

```bash
sudo setenforce permissive
```

> This is a temporary fix. For a permanent solution, adjust SELinux policy accordingly.

## Security note

This script changes system DNS settings and locks `/etc/resolv.conf` on Arch.
Review the script and config files before running.
Use DPI bypass tools only where legal.

## File structure

```
zapret-installation/
├── arch/
│   ├── zapret-installation.sh
│   ├── config
│   └── dnscrypt-proxy.toml
├── debian/
│   ├── zapret-installation.sh
│   ├── config
│   └── dnscrypt-proxy.toml
├── fedora/
│   ├── zapret-installation.sh
│   ├── config
│   └── dnscrypt-proxy.toml
├── bazzite/
│   ├── zapret-installation.sh
│   ├── config
│   └── dnscrypt-proxy.toml
├── README.md
└── LICENSE
```

## Contributing

Contributions are welcome:

- Bug fixes
- Documentation improvements
- Support for more distributions

## Acknowledgements

This project automates installation and setup around these upstream projects:

- [zapret](https://github.com/bol-van/zapret) — DPI bypass toolkit
- [zapret-git (AUR)](https://aur.archlinux.org/packages/zapret-git)
- [dnscrypt-proxy](https://github.com/DNSCrypt/dnscrypt-proxy) — encrypted DNS proxy

Thanks to the maintainers and contributors of these projects.

## License

See [LICENSE](LICENSE).

## Disclaimer

This project is provided for educational and legitimate use.
You are responsible for complying with local laws and regulations.
