# zapret-installation

A simple installer script for **Zapret** and **DNSCrypt-Proxy** on **Arch-based Linux**.

## What this project does

This project helps you install and configure:

- **Zapret** (DPI bypass tool)
- **DNSCrypt-Proxy** (encrypted DNS proxy)

It automates common setup steps so you don’t need to do everything manually.

## Supported systems

- Arch Linux
- Arch-based distros (Manjaro, EndeavourOS, etc.)

## What the script handles

- Checks `sudo` access
- Verifies `yay` and `chattr`
- Installs `curl` if missing
- Installs `zapret-git` and `dnscrypt-proxy` if not installed
- Uses local config files (`arch/config`, `arch/dnscrypt-proxy.toml`) when available
- Otherwise downloads config files from GitHub raw URLs
- Copies config files to:
  - `/etc/dnscrypt-proxy/`
  - `/opt/zapret/`
- Disables `systemd-resolved` units if they exist
- Enables and restarts `dnscrypt-proxy`
- Sets NetworkManager DNS mode to `dns=none`
- Writes `nameserver 127.0.0.1` to `/etc/resolv.conf`
- Protects `/etc/resolv.conf` with `chattr +i`
- Lets you add domains to Zapret exclude list interactively
- Enables Zapret service
- Optionally removes temporary config folder: `$HOME/zapretconfigs`

## Requirements

- Arch-based Linux
- `yay`
- `sudo` privileges
- Internet access

> `chattr` is usually already present on Arch systems.

## Installation

1. Clone the repository:

```/dev/null/README.md#L1-2
git clone https://github.com/ZaferOrucoglu/zapret-installation.git
cd zapret-installation
```

2. Run the script:

```/dev/null/README.md#L1-2
chmod +x arch/zapret-installation.sh
./arch/zapret-installation.sh
```

3. Follow prompts to:
   - Continue installation flow
   - Add domains to Zapret exclude list (optional)
   - Keep or remove `$HOME/zapretconfigs`

## Important paths

- Script: `arch/zapret-installation.sh`
- DNSCrypt config target: `/etc/dnscrypt-proxy/dnscrypt-proxy.toml`
- Zapret config target: `/opt/zapret/config`
- Zapret exclude list: `/opt/zapret/ipset/zapret-hosts-user-exclude.txt`
- Temporary config dir: `$HOME/zapretconfigs`

## After installation

### Edit DNSCrypt config

```/dev/null/README.md#L1-2
sudo nano /etc/dnscrypt-proxy/dnscrypt-proxy.toml
sudo systemctl restart dnscrypt-proxy
```

### Add a domain to Zapret exclude list manually

```/dev/null/README.md#L1-2
echo "example.com" | sudo tee -a /opt/zapret/ipset/zapret-hosts-user-exclude.txt
sudo systemctl restart zapret
```

### Make `/etc/resolv.conf` editable again

```/dev/null/README.md#L1-1
sudo chattr -i /etc/resolv.conf
```

If needed, protect it again:

```/dev/null/README.md#L1-1
sudo chattr +i /etc/resolv.conf
```

## Troubleshooting

### DNS not working

Restart services:

```/dev/null/README.md#L1-2
sudo systemctl restart dnscrypt-proxy
sudo systemctl restart NetworkManager
```

Check resolver file:

```/dev/null/README.md#L1-1
cat /etc/resolv.conf
```

### Service status checks

```/dev/null/README.md#L1-3
systemctl status dnscrypt-proxy
systemctl status zapret
systemctl status systemd-resolved
```

### Config download issues

If local config files are not found, the script downloads from GitHub raw URLs.  
Make sure your internet connection works and GitHub is reachable.

## Security note

This script changes system DNS settings and locks `/etc/resolv.conf`.  
Review the script and config files before running.  
Use DPI bypass tools only where legal.

## File structure

```/dev/null/README.md#L1-9
zapret-installation/
├── arch/
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
