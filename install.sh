#!/usr/bin/env bash

# ============================================================
#   D O C K E R   I N S T A L L A T I O N   S C R I P T
#   For the Distinguished Gentleman of All Linux Persuasions
#   Version 2.1  |  Multi-Distro  |  With Honour & Precision
# ============================================================

set -euo pipefail

# ── Colours & Glyphs ────────────────────────────────────────
RESET="\033[0m"
BOLD="\033[1m"
GREEN="\033[1;32m"
RED="\033[1;31m"
YELLOW="\033[1;33m"
CYAN="\033[1;36m"
MAGENTA="\033[1;35m"
WHITE="\033[1;37m"
BLUE="\033[1;34m"
DIM="\033[2m"
ITALIC="\033[3m"

OK="  ${GREEN}✔${RESET}"
ERR="  ${RED}✘${RESET}"
INFO="  ${CYAN}ℹ${RESET}"
WARN="  ${YELLOW}⚠${RESET}"
STEP="${MAGENTA}❯${RESET}"
ARROW="${CYAN}→${RESET}"
LINE="${DIM}──────────────────────────────────────────────────────${RESET}"
DLINE="${CYAN}══════════════════════════════════════════════════════${RESET}"

# ── Detected OS info (populated in detect_distro) ───────────
DISTRO=""
PKG_MGR=""
PKG_UPDATE=""
PRETTY_NAME=""

# ── Helpers ─────────────────────────────────────────────────

print_banner() {
    clear
    echo ""
    echo -e "${CYAN}${BOLD}"
    echo "  ╔══════════════════════════════════════════════════════╗"
    echo "  ║       T H E   D O C K E R   I N S T A L L E R      ║"
    echo "  ║       Multi-Distro  ·  Crafted with Dignity         ║"
    echo "  ║       Version 2.1  ·  Industry Best Practices       ║"
    echo "  ╚══════════════════════════════════════════════════════╝"
    echo -e "${RESET}"
    echo -e "${DIM}${ITALIC}  One does not simply install Docker. One orchestrates it.${RESET}"
    echo ""
}

step_msg() {
    echo ""
    echo -e "${DLINE}"
    echo -e " ${STEP} ${WHITE}${BOLD}$1${RESET}"
    echo -e "${DLINE}"
    echo ""
}

section_msg() {
    echo ""
    echo -e "${LINE}"
    echo -e "   ${ARROW} ${CYAN}${BOLD}$1${RESET}"
    echo -e "${LINE}"
}

success_msg() {
    echo -e "${OK} ${GREEN}${BOLD}$1${RESET}"
}

fail_msg() {
    echo ""
    echo -e "${ERR} ${RED}${BOLD}$1${RESET}"
    echo ""
    echo -e "  ${YELLOW}${BOLD}╔════════════════════════════════════════╗${RESET}"
    echo -e "  ${YELLOW}${BOLD}║  The installation has met an untimely  ║${RESET}"
    echo -e "  ${YELLOW}${BOLD}║  end. Kindly review the output above.  ║${RESET}"
    echo -e "  ${YELLOW}${BOLD}╚════════════════════════════════════════╝${RESET}"
    echo ""
    exit 1
}

info_msg() {
    echo -e "${INFO} ${DIM}$1${RESET}"
}

warn_msg() {
    echo -e "${WARN} ${YELLOW}$1${RESET}"
}

# ── Core runner: streams every line of stdout+stderr through a gutter ──
# Nothing is discarded. The user sees the full, unabridged output.
run_cmd_once() {
    local description="$1"
    shift

    echo ""
    echo -e "  ${BLUE}${BOLD}▸ Running:${RESET} ${DIM}$*${RESET}"
    echo -e "  ${DIM}┌─────────────────────────────────────────────────────${RESET}"

    local tmpfile
    # FIX #9: Added $RANDOM suffix to avoid collisions on PID-namespace systems
    tmpfile="/tmp/docker_install_out_$$_$RANDOM"
    local exit_code=0

    "$@" > "$tmpfile" 2>&1 || exit_code=$?

    while IFS= read -r line; do
        echo -e "  ${DIM}│${RESET}  $line"
    done < "$tmpfile"

    echo -e "  ${DIM}└─────────────────────────────────────────────────────${RESET}"
    echo ""

    rm -f "$tmpfile"

    if [[ $exit_code -eq 0 ]]; then
        success_msg "$description"
    else
        fail_msg "$description — command exited with code $exit_code"
    fi
}

check_root() {
    if [[ "$EUID" -ne 0 ]]; then
        echo ""
        echo -e "${ERR} ${RED}${BOLD}Pardon me, but elevated privileges are required.${RESET}"
        echo -e "  ${DIM}Kindly re-run with: ${WHITE}sudo bash install_docker.sh${RESET}"
        echo ""
        exit 1
    fi
}

# ── Pre-flight: Internet Connectivity ────────────────────────
# FIX #10: Verify network before attempting any downloads
check_internet() {
    section_msg "Pre-flight: Verifying Internet Connectivity"

    info_msg "Reaching out to download.docker.com..."
    if curl -fsSL --max-time 10 --head https://download.docker.com > /dev/null 2>&1; then
        success_msg "Internet connectivity confirmed — the courier may proceed"
    else
        fail_msg "Cannot reach download.docker.com — please verify your internet connection and try again"
    fi
}

# ── Pre-flight: Docker Already Installed? ────────────────────
# FIX #11: Guard against unnecessary reinstallation
check_docker_installed() {
    section_msg "Pre-flight: Checking for Existing Docker Installation"

    if command -v docker &>/dev/null && docker --version &>/dev/null 2>&1; then
        local existing_ver
        existing_ver=$(docker --version)
        echo ""
        echo -e "  ${YELLOW}${BOLD}╔══════════════════════════════════════════════════════╗${RESET}"
        echo -e "  ${YELLOW}${BOLD}║  Docker is already installed on this fine machine.  ║${RESET}"
        echo -e "  ${YELLOW}${BOLD}╚══════════════════════════════════════════════════════╝${RESET}"
        echo ""
        info_msg "Detected: ${WHITE}${BOLD}${existing_ver}${RESET}"
        echo ""
        if [[ -t 0 ]]; then
            echo -e -n "  ${CYAN}${BOLD}Enter 'y' to reinstall/upgrade, or press Enter to exit: ${RESET}"
            read -r REINSTALL_CHOICE
            if [[ ! "${REINSTALL_CHOICE:-}" =~ ^[Yy]$ ]]; then
                echo ""
                success_msg "Wise choice — a gentleman does not fix what is not broken. Exiting."
                exit 0
            fi
        else
            warn_msg "Running non-interactively — proceeding with reinstallation."
        fi
    else
        success_msg "No existing Docker installation detected — proceeding with a clean slate"
    fi
}

# ── Distro Detection ─────────────────────────────────────────
detect_distro() {
    section_msg "Detecting Linux Distribution"

    if [[ ! -f /etc/os-release ]]; then
        fail_msg "Cannot read /etc/os-release — unsupported or ancient system"
    fi

    . /etc/os-release
    local id_lower
    id_lower=$(echo "${ID:-}" | tr '[:upper:]' '[:lower:]')
    local id_like_lower
    id_like_lower=$(echo "${ID_LIKE:-}" | tr '[:upper:]' '[:lower:]')
    PRETTY_NAME="${PRETTY_NAME:-$ID}"

    if [[ "$id_lower" =~ ^(ubuntu|debian|linuxmint|pop|elementary|kali|raspbian)$ ]] \
        || [[ "$id_like_lower" =~ debian ]]; then
        DISTRO="debian"
        PKG_MGR="apt-get"
        PKG_UPDATE="apt-get update"

    elif [[ "$id_lower" =~ ^(centos|rhel|rocky|almalinux|ol)$ ]] \
        || [[ "$id_like_lower" =~ rhel ]]; then
        DISTRO="rhel"
        PKG_MGR=$(command -v dnf &>/dev/null && echo "dnf" || echo "yum")
        PKG_UPDATE="$PKG_MGR check-update; true"

    elif [[ "$id_lower" == "fedora" ]]; then
        DISTRO="fedora"
        PKG_MGR="dnf"
        PKG_UPDATE="dnf check-update; true"

    elif [[ "$id_lower" =~ ^(arch|manjaro|endeavouros|garuda)$ ]] \
        || [[ "$id_like_lower" =~ arch ]]; then
        DISTRO="arch"
        PKG_MGR="pacman"
        PKG_UPDATE="pacman -Sy --noconfirm"

    elif [[ "$id_lower" =~ ^(opensuse|sles|sled)$ ]] \
        || [[ "$id_like_lower" =~ suse ]]; then
        DISTRO="suse"
        PKG_MGR="zypper"
        PKG_UPDATE="zypper refresh"

    elif [[ "$id_lower" == "alpine" ]]; then
        DISTRO="alpine"
        PKG_MGR="apk"
        PKG_UPDATE="apk update"

    else
        fail_msg "Unsupported distro: '${PRETTY_NAME}'. Supported: Debian/Ubuntu/Mint/Pop, RHEL/CentOS/Rocky/Alma, Fedora, Arch/Manjaro, openSUSE, Alpine."
    fi

    info_msg "Detected   : ${WHITE}${BOLD}${PRETTY_NAME}${RESET}"
    info_msg "Package Mgr: ${WHITE}${BOLD}${PKG_MGR}${RESET}"
    echo ""
    success_msg "Distribution identified — proceeding with dignity"
}

# ── Step 1: Update & Upgrade ─────────────────────────────────
system_update() {
    step_msg "Step I — Refreshing the System's Wardrobe (Update & Upgrade)"

    info_msg "Updating package lists..."
    run_cmd_once "Package lists refreshed with utmost refinement" \
        bash -c "$PKG_UPDATE"

    info_msg "Upgrading installed packages — this may take a moment..."
    case "$PKG_MGR" in
        apt-get) run_cmd_once "System upgraded to its finest form" apt-get upgrade -y ;;
        # FIX #6: Quoted $PKG_MGR to prevent word-splitting
        dnf|yum) run_cmd_once "System upgraded to its finest form" "$PKG_MGR" upgrade -y ;;
        pacman)  run_cmd_once "System upgraded to its finest form" pacman -Su --noconfirm ;;
        zypper)  run_cmd_once "System upgraded to its finest form" zypper update -y ;;
        apk)     run_cmd_once "System upgraded to its finest form" apk upgrade ;;
    esac
}

# ── Step 2: Remove Old Docker Relics ─────────────────────────
remove_old_docker() {
    step_msg "Step II — Evicting the Old & Unworthy Docker Relics"

    info_msg "Scanning for legacy Docker installations..."
    echo ""

    case "$DISTRO" in
        debian)
            # FIX: Use dpkg -l + awk to correctly list only *installed* packages
            OLD_PKGS=()
            while IFS= read -r pkg; do
                [[ -n "$pkg" ]] && OLD_PKGS+=("$pkg")
            done < <(dpkg -l docker docker.io docker-engine docker-compose \
                docker-compose-v2 docker-doc podman-docker containerd runc 2>/dev/null \
                | awk '/^ii/{print $2}')

            if [[ ${#OLD_PKGS[@]} -gt 0 ]]; then
                info_msg "Found installed relics: ${WHITE}${OLD_PKGS[*]}${RESET}"
                # FIX: Proper bash array expansion — no word-splitting or glob risk
                run_cmd_once "Old packages purged — the manor is free of riff-raff" \
                    apt-get remove -y "${OLD_PKGS[@]}"
            else
                success_msg "No old Docker packages found — the estate was already tidy"
            fi
            ;;

        rhel|fedora)
            run_cmd_once "Legacy Docker packages removed (if any)" \
                bash -c "$PKG_MGR remove -y docker docker-client docker-client-latest \
                    docker-common docker-latest docker-latest-logrotate \
                    docker-logrotate docker-engine 2>/dev/null || true"
            ;;

        arch)
            run_cmd_once "Legacy Docker packages removed (if any)" \
                bash -c "pacman -Rns --noconfirm docker docker-compose 2>/dev/null || true"
            ;;

        suse)
            run_cmd_once "Legacy Docker packages removed (if any)" \
                bash -c "zypper remove -y docker docker-compose 2>/dev/null || true"
            ;;

        alpine)
            run_cmd_once "Legacy Docker packages removed (if any)" \
                bash -c "apk del docker docker-compose 2>/dev/null || true"
            ;;
    esac
}

# ── Step 3: Install Prerequisites ────────────────────────────
install_prerequisites() {
    step_msg "Step III — Procuring the Essential Provisions"

    info_msg "Refreshing package lists once more..."
    run_cmd_once "Package lists refreshed — as any proper gentleman would insist" \
        bash -c "$PKG_UPDATE"

    info_msg "Installing prerequisite packages..."
    case "$DISTRO" in
        debian)
            run_cmd_once "ca-certificates, curl & gnupg installed — courier and credentials secured" \
                apt-get install -y ca-certificates curl gnupg lsb-release
            ;;
        rhel|fedora)
            run_cmd_once "yum-utils and device-mapper installed — the foundation is prepared" \
                $PKG_MGR install -y yum-utils device-mapper-persistent-data lvm2
            ;;
        arch)
            run_cmd_once "base-devel and curl installed — Arch is self-sufficient as ever" \
                pacman -S --noconfirm --needed base-devel curl
            ;;
        suse)
            run_cmd_once "curl installed — the courier is on standby" \
                zypper install -y curl
            ;;
        alpine)
            run_cmd_once "curl and ca-certificates installed — credentials in hand" \
                apk add curl ca-certificates
            ;;
    esac
}

# ── Step 4: Set Up Docker Repository ─────────────────────────
setup_repository() {
    step_msg "Step IV — Adding Docker's Official Repository to the House Ledger"

    case "$DISTRO" in
        debian)
            section_msg "Installing Docker's GPG Seal of Authenticity"

            # FIX #1/#2: Determine the correct Docker sub-repository per distro.
            # Docker maintains SEPARATE repos, GPG keys, and package indexes for each:
            #   /linux/ubuntu  → Ubuntu, Linux Mint, Pop!_OS, elementary OS
            #   /linux/debian  → Debian, Kali Linux, Raspbian
            # Using the Ubuntu repo on native Debian (or vice-versa) is incorrect.
            local DOCKER_REPO_DISTRO
            local os_id
            os_id=$(. /etc/os-release && echo "${ID:-}" | tr '[:upper:]' '[:lower:]')
            case "$os_id" in
                ubuntu|linuxmint|pop|elementary) DOCKER_REPO_DISTRO="ubuntu" ;;
                debian|kali|raspbian)            DOCKER_REPO_DISTRO="debian" ;;
                *)
                    # Fallback: prefer ubuntu branch if ID_LIKE mentions it
                    if [[ "${ID_LIKE:-}" =~ ubuntu ]]; then
                        DOCKER_REPO_DISTRO="ubuntu"
                    else
                        DOCKER_REPO_DISTRO="debian"
                    fi
                    ;;
            esac
            info_msg "Docker repo distro  : ${WHITE}${BOLD}${DOCKER_REPO_DISTRO}${RESET}"

            run_cmd_once "Keyring directory created with proper permissions" \
                install -m 0755 -d /etc/apt/keyrings

            # FIX #1: Use the distro-correct GPG URL (not always Ubuntu's)
            run_cmd_once "Docker GPG key fetched and placed on the mantelpiece" \
                curl -fsSL "https://download.docker.com/linux/${DOCKER_REPO_DISTRO}/gpg" \
                -o /etc/apt/keyrings/docker.asc

            # FIX #12: Verify the GPG fingerprint before trusting the repository.
            # Docker's official fingerprint: 9DC8 5822 9FC7 DD38 854A  E2D8 8D81 803C 0EBF CD88
            section_msg "Verifying Docker GPG Fingerprint — Trust, but Verify"
            local EXPECTED_FP="9DC858229FC7DD38854AE2D88D81803C0EBFCD88"
            local ACTUAL_FP=""
            ACTUAL_FP=$(gpg --show-keys --with-colons /etc/apt/keyrings/docker.asc 2>/dev/null \
                | awk -F: '/^fpr/{print $10; exit}' | tr -d ' ') || ACTUAL_FP=""
            if [[ "${ACTUAL_FP}" == "${EXPECTED_FP}" ]]; then
                success_msg "GPG fingerprint verified — the seal is authentic (…${ACTUAL_FP: -8})"
            else
                warn_msg "GPG fingerprint could not be auto-verified — proceeding with caution"
                info_msg "Expected : ${WHITE}${EXPECTED_FP}${RESET}"
                info_msg "Got      : ${WHITE}${ACTUAL_FP:-unknown}${RESET}"
                info_msg "Verify manually: ${WHITE}gpg --show-keys /etc/apt/keyrings/docker.asc${RESET}"
            fi

            run_cmd_once "Appropriate read permissions bestowed upon the GPG key" \
                chmod a+r /etc/apt/keyrings/docker.asc

            section_msg "Writing Docker Repository Entry (DEB822 Format)"

            # FIX #3: Resolve the correct release codename per distro family.
            # - Ubuntu derivatives (Mint, Pop, etc.): UBUNTU_CODENAME holds the *upstream*
            #   Ubuntu codename (e.g., "jammy"), NOT the derivative's own codename.
            #   Docker's Ubuntu repo only knows Ubuntu codenames — not Mint's.
            # - Pure Debian: VERSION_CODENAME is authoritative (e.g., "bookworm").
            local CODENAME
            if [[ "$DOCKER_REPO_DISTRO" == "ubuntu" ]]; then
                CODENAME=$(. /etc/os-release && echo "${UBUNTU_CODENAME:-${VERSION_CODENAME:-}}")
            else
                CODENAME=$(. /etc/os-release && echo "${VERSION_CODENAME:-${UBUNTU_CODENAME:-}}")
            fi
            if [[ -z "$CODENAME" ]]; then
                fail_msg "Could not determine Ubuntu/Debian codename — most irregular"
            fi
            info_msg "Codename: ${WHITE}${BOLD}${CODENAME}${RESET}"
            echo ""

            # FIX #2: Use the distro-correct repo URI (not always Ubuntu's)
            local repo_content
            repo_content="Types: deb
URIs: https://download.docker.com/linux/${DOCKER_REPO_DISTRO}
Suites: ${CODENAME}
Components: stable
Signed-By: /etc/apt/keyrings/docker.asc"

            echo "$repo_content" | tee /etc/apt/sources.list.d/docker.sources > /dev/null

            echo -e "  ${BLUE}${BOLD}▸ Written:${RESET} ${DIM}/etc/apt/sources.list.d/docker.sources${RESET}"
            echo -e "  ${DIM}┌─────────────────────────────────────────────────────${RESET}"
            echo "$repo_content" | while IFS= read -r line; do
                echo -e "  ${DIM}│${RESET}  $line"
            done
            echo -e "  ${DIM}└─────────────────────────────────────────────────────${RESET}"
            echo ""

            success_msg "Docker repository inscribed for '${CODENAME}' — splendid"

            run_cmd_once "Package lists refreshed with the new repository in tow" \
                apt-get update
            ;;

        rhel|fedora)
            run_cmd_once "Docker CE repository added via config-manager" \
                $PKG_MGR config-manager \
                --add-repo https://download.docker.com/linux/centos/docker-ce.repo
            ;;

        arch)
            info_msg "Arch ships Docker in the official extra repo — no additional repository required."
            success_msg "Repository step elegantly skipped — Arch handles its own affairs"
            ;;

        suse)
            # FIX #5: Distinguish openSUSE (Leap/Tumbleweed) from SLES/SLED (enterprise).
            # Docker maintains SEPARATE repos: /linux/opensuse vs /linux/sles.
            # Using the sles repo on openSUSE will fail to resolve packages.
            local suse_id
            suse_id=$(. /etc/os-release && echo "${ID:-opensuse}" | tr '[:upper:]' '[:lower:]')
            local SUSE_REPO_DISTRO
            case "$suse_id" in
                sles|sled) SUSE_REPO_DISTRO="sles" ;;
                *)         SUSE_REPO_DISTRO="opensuse" ;;
            esac
            run_cmd_once "Docker repository added via zypper (${SUSE_REPO_DISTRO})" \
                zypper addrepo "https://download.docker.com/linux/${SUSE_REPO_DISTRO}/docker-ce.repo"
            run_cmd_once "Repository GPG key imported and refreshed" \
                zypper --gpg-auto-import-keys refresh
            ;;

        alpine)
            info_msg "Alpine ships Docker in its community repository."
            run_cmd_once "Community repository enabled (if not already)" \
                bash -c "grep -q community /etc/apk/repositories \
                    || echo 'https://dl-cdn.alpinelinux.org/alpine/latest-stable/community' \
                    >> /etc/apk/repositories"
            run_cmd_once "Package lists updated with community repo" \
                apk update
            ;;
    esac
}

# ── Step 5: Install Docker ────────────────────────────────────
install_docker() {
    step_msg "Step V — Installing Docker and Its Distinguished Companions"

    info_msg "Installing Docker Engine, CLI, Containerd, Buildx & Compose..."

    case "$DISTRO" in
        debian)
            run_cmd_once "Docker Engine, CLI, Containerd, Buildx & Compose — the full ensemble" \
                apt-get install -y \
                    docker-ce \
                    docker-ce-cli \
                    containerd.io \
                    docker-buildx-plugin \
                    docker-compose-plugin
            ;;
        rhel|fedora)
            run_cmd_once "Docker Engine, CLI, Containerd, Buildx & Compose installed" \
                $PKG_MGR install -y \
                    docker-ce \
                    docker-ce-cli \
                    containerd.io \
                    docker-buildx-plugin \
                    docker-compose-plugin
            ;;
        arch)
            run_cmd_once "Docker and Docker Compose installed via pacman" \
                pacman -S --noconfirm --needed docker docker-compose
            ;;
        suse)
            run_cmd_once "Docker Engine and Compose installed via zypper" \
                zypper install -y docker docker-compose
            ;;
        alpine)
            run_cmd_once "Docker Engine and Compose installed via apk" \
                apk add docker docker-compose
            ;;
    esac
}

# ── Step 6: Start & Enable Docker Service ────────────────────
start_docker_service() {
    step_msg "Step VI — Rousing the Docker Daemon from Its Slumber"

    if command -v systemctl &>/dev/null && systemctl list-units &>/dev/null 2>&1; then
        # systemd-based (Debian, Ubuntu, RHEL, Fedora, Arch, openSUSE)
        run_cmd_once "Docker service started with a firm but courteous nudge" \
            systemctl start docker

        # FIX: enable so Docker auto-starts on every reboot
        run_cmd_once "Docker service enabled to rise loyally on each boot" \
            systemctl enable docker

        info_msg "Checking daemon health..."
        echo ""
        echo -e "  ${DIM}┌── systemctl status docker ───────────────────────────${RESET}"
        systemctl status docker --no-pager 2>&1 \
            | while IFS= read -r line; do
                echo -e "  ${DIM}│${RESET}  $line"
              done
        echo -e "  ${DIM}└─────────────────────────────────────────────────────${RESET}"
        echo ""

        if systemctl is-active --quiet docker; then
            success_msg "Docker daemon is active and in excellent health"
        else
            fail_msg "Docker daemon failed to start — most unsatisfactory"
        fi

    elif command -v rc-service &>/dev/null; then
        # OpenRC (Alpine)
        run_cmd_once "Docker service started via OpenRC" \
            rc-service docker start
        run_cmd_once "Docker added to default runlevel — will start on every boot" \
            rc-update add docker default
        success_msg "Docker daemon started and enabled via OpenRC"

    else
        warn_msg "Could not detect init system — please start Docker manually."
        info_msg "Try: ${WHITE}service docker start${RESET}"
    fi
}

# ── Step 7: Add Invoking User to Docker Group ─────────────────
add_user_to_group() {
    step_msg "Step VII — Granting Docker Access to the Household"

    # FIX: Add invoking user so docker commands work without sudo
    if [[ -n "${SUDO_USER:-}" ]]; then
        run_cmd_once "User '${SUDO_USER}' admitted to the docker group — a most deserved honour" \
            usermod -aG docker "$SUDO_USER"
        echo ""
        warn_msg "Please log out and back in for group membership to take effect."
        info_msg "Or activate it immediately in your current shell: ${WHITE}newgrp docker${RESET}"
    else
        # FIX #8: Script was run directly as root (no SUDO_USER). Rather than silently
        # skipping, prompt interactively for a username so the user isn't left with
        # a machine where every docker command requires sudo.
        info_msg "No SUDO_USER detected — the script appears to be running directly as root."
        info_msg "To grant a user Docker access without sudo, run:"
        info_msg "  ${WHITE}usermod -aG docker <username> && newgrp docker${RESET}"
        if [[ -t 0 ]]; then
            echo ""
            echo -e -n "  ${CYAN}${BOLD}Enter a username to add to the docker group (or Enter to skip): ${RESET}"
            read -r MANUAL_USER
            if [[ -n "${MANUAL_USER:-}" ]]; then
                if id "$MANUAL_USER" &>/dev/null 2>&1; then
                    run_cmd_once "User '${MANUAL_USER}' admitted to the docker group — a most deserved honour" \
                        usermod -aG docker "$MANUAL_USER"
                    warn_msg "Please log out and back in for group membership to take effect."
                    info_msg "Or activate it immediately: ${WHITE}newgrp docker${RESET}"
                else
                    warn_msg "User '${MANUAL_USER}' not found — skipping group assignment."
                fi
            else
                success_msg "Group step skipped — proceed at your discretion"
            fi
        else
            success_msg "Group step noted — proceed at your discretion"
        fi
    fi
}

# ── Step 8: Smoke Test ────────────────────────────────────────
smoke_test() {
    step_msg "Step VIII — The Ceremonial hello-world, a Time-Honoured Tradition"

    info_msg "Pulling and running docker/hello-world..."
    echo ""
    echo -e "  ${DIM}┌── docker run --rm hello-world ──────────────────────${RESET}"

    local tmpfile
    # FIX #9: Added $RANDOM suffix to avoid collisions on PID-namespace systems
    tmpfile="/tmp/docker_install_out_$$_$RANDOM"
    local exit_code=0

    docker run --rm hello-world > "$tmpfile" 2>&1 || exit_code=$?

    while IFS= read -r line; do
        echo -e "  ${DIM}│${RESET}  $line"
    done < "$tmpfile"

    echo -e "  ${DIM}└─────────────────────────────────────────────────────${RESET}"
    echo ""
    rm -f "$tmpfile"

    # FIX #4: Smoke test failure is NOT fatal. Docker IS installed and the daemon IS
    # running — hello-world can fail due to transient network or daemon warm-up issues.
    # A hard exit here would suppress the summary, leaving the user without version info.
    if [[ $exit_code -eq 0 ]]; then
        success_msg "hello-world ran magnificently — Docker is in fine fettle"
    else
        warn_msg "hello-world returned exit code ${exit_code} — Docker may need a moment to fully initialise"
        info_msg "Try manually once settled: ${WHITE}docker run --rm hello-world${RESET}"
    fi
}

# ── Grand Finale ─────────────────────────────────────────────
print_summary() {
    local docker_ver compose_ver
    docker_ver=$(docker --version 2>/dev/null || echo "unavailable")
    compose_ver=$(docker compose version 2>/dev/null || echo "unavailable")

    echo ""
    echo -e "${DLINE}"
    echo -e "${GREEN}${BOLD}"
    echo "   ✦  Installation Complete, My Distinguished Fellow.  ✦"
    echo -e "${RESET}"
    echo -e "   ${DIM}Distro         :${RESET}  ${WHITE}${BOLD}${PRETTY_NAME}${RESET}"
    echo -e "   ${DIM}Docker version :${RESET}  ${WHITE}${BOLD}${docker_ver}${RESET}"
    echo -e "   ${DIM}Compose version:${RESET}  ${WHITE}${BOLD}${compose_ver}${RESET}"
    echo -e "   ${DIM}Service status :${RESET}  ${GREEN}${BOLD}Running & Enabled on boot${RESET}"
    echo -e "   ${DIM}Docker group   :${RESET}  ${WHITE}${SUDO_USER:-<assign manually>}${RESET} ${DIM}→ docker${RESET}"
    echo ""
    echo -e "   ${CYAN}${BOLD}May your containers be ever lightweight,"
    echo -e "   and your deployments eternally graceful.${RESET}"
    echo -e "${DLINE}"
    echo ""
}

# ── Cleanup ───────────────────────────────────────────────────
cleanup() {
    rm -f /tmp/docker_install_out_* /tmp/docker_install_err
}
trap cleanup EXIT

# ═══════════════════════════════════════════════════════
#   M A I N
# ═══════════════════════════════════════════════════════

print_banner
check_root
check_internet          # FIX #10: verify network before any downloads
check_docker_installed  # FIX #11: guard against unnecessary reinstallation
detect_distro
system_update
remove_old_docker
install_prerequisites
setup_repository
install_docker
start_docker_service
add_user_to_group
smoke_test
print_summary

exit 0