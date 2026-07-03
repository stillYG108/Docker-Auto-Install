```text
████▄   ▄▄▄   ▄▄▄▄ ▄▄ ▄▄ ▄▄▄▄▄ ▄▄▄▄
██  ██ ██▀██ ██▀▀▀ ██▄█▀ ██▄▄  ██▄█▄
████▀  ▀███▀ ▀████ ██ ██ ██▄▄▄ ██ ██

▄████▄ ▄▄ ▄▄ ▄▄▄▄▄▄ ▄▄▄
██▄▄██ ██ ██   ██  ██▀██
██  ██ ▀███▀   ██  ▀███▀

██ ▄▄  ▄▄  ▄▄▄▄ ▄▄▄▄▄▄ ▄▄▄  ▄▄    ▄▄    ▄▄▄▄▄ ▄▄▄▄
██ ███▄██ ███▄▄   ██  ██▀██ ██    ██    ██▄▄  ██▄█▄
██ ██ ▀██ ▄▄██▀   ██  ██▀██ ██▄▄▄ ██▄▄▄ ██▄▄▄ ██ ██
```

> **One does not simply install Docker. One orchestrates it.**  
> Detects your distro, installs Docker Engine, CLI, Compose, Buildx & Containerd — crafted with dignity.

---

## Quick Start — No Dependencies Required ⭐

The primary distribution method is a **plain bash script** — works on any fresh Linux machine with zero prerequisites.

### Using `curl`

```bash
curl -fsSL https://raw.githubusercontent.com/stillYG108/Docker-Auto-Install/main/install.sh | sudo bash
```

### Using `wget`

```bash
wget -qO- https://raw.githubusercontent.com/stillYG108/Docker-Auto-Install/main/install.sh | sudo bash
```

### Download and inspect first (recommended on production systems)

```bash
curl -fsSL https://raw.githubusercontent.com/stillYG108/Docker-Auto-Install/main/install.sh -o install-docker.sh
# Review the script
less install-docker.sh
# Run it
sudo bash install-docker.sh
```

### Git clone

```bash
git clone https://github.com/stillYG108/Docker-Auto-Install
cd Docker-Auto-Install
sudo bash install.sh
```

> **This method requires nothing but `bash` and `curl` (or `wget`) — ideal for fresh EC2 instances, VPSs, cloud VMs, Raspberry Pi, and any bare Linux server.**

---

## For Node.js Developers (npm / npx)

If you're already in a Node.js environment, you can use the npm package instead:

### One-shot via npx

```bash
npx docker-auto-install
```

### Global install

```bash
npm install -g docker-auto-install
docker-auto-install
```

> **Note:** Requires Node.js ≥ 14. The npm package is a thin wrapper that invokes the same bash script under the hood.  
> If Node.js isn't installed yet, use the `curl` method above — it's faster and has no prerequisites.

---

## Supported Distributions

| Family | Distros |
|--------|---------|
| **Debian / Ubuntu** | Ubuntu, Debian, Linux Mint, Pop!\_OS, elementary OS, Kali Linux, Raspbian |
| **RHEL / CentOS** | RHEL, CentOS, Rocky Linux, AlmaLinux, Oracle Linux |
| **Fedora** | Fedora |
| **Arch Linux** | Arch, Manjaro, EndeavourOS, Garuda |
| **openSUSE / SLES** | openSUSE Leap, openSUSE Tumbleweed, SLES, SLED |
| **Alpine Linux** | Alpine |

---

## What It Does

```
Pre-flight: verify internet connectivity
Pre-flight: check if Docker is already installed (offer graceful exit)
      │
      ▼
Detect Linux distribution  (/etc/os-release)
      │
      ▼
Update package index & upgrade packages
      │
      ▼
Remove old Docker relics  (docker.io, docker-engine, etc.)
      │
      ▼
Install prerequisites  (curl, ca-certificates, gnupg, etc.)
      │
      ▼
Add Docker's official repository
   ├─ Downloads distro-correct GPG key
   ├─ Verifies GPG fingerprint  (9DC8 5822 9FC7 DD38 …)
   └─ Writes signed DEB822 / RPM / zypper source entry
      │
      ▼
Install Docker Engine + CLI + Containerd + Buildx + Compose
      │
      ▼
Start & enable Docker service  (systemd or OpenRC)
      │
      ▼
Add invoking user to the docker group
      │
      ▼
Run hello-world smoke test
      │
      ▼
Print installation summary
```

---

## Project Structure

```
docker-auto-install/
├── install.sh                    ← PRIMARY: curl this on any fresh Linux machine
├── scripts/
│   └── the_docker_installation.sh  ← Bundled copy used by the npm package
├── bin/
│   └── docker-auto-install.js    ← Node.js CLI shim (npm / npx entry point)
├── package.json
├── LICENSE
└── README.md
```

---

## Requirements

| Method | Requirements |
|--------|-------------|
| `curl \| bash` | `bash`, `curl` or `wget`, `sudo` or root |
| `git clone` | `git`, `bash`, `sudo` or root |
| `npx` / `npm` | Node.js ≥ 14, `bash`, `sudo` or root |

## License

MIT © [stillYG108](https://github.com/stillYG108)
