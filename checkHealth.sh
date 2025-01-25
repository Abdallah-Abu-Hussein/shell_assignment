#!/usr/bin/env bash
#
# health_check_fastfetch_installer.sh
#
# Description:
#   1. Detects if the distro is Arch or Ubuntu (fallback "other").
#   2. Installs fastfetch if missing (using pacman or apt-get).
#   3. Uses fastfetch for ASCII art if installed successfully, else a generic banner.
#   4. Performs minimal health checks (disk, memory, CPU load, services, updates).
#   5. Logs exactly 2 lines per check, then prints the entire log.
#

# ------------------ CONFIGURATION ------------------
LOG_FILE="/var/log/health_check.log"

# Services to check (systemd names):
SERVICES_TO_CHECK=(
    "sshd"
    "cron"
)

# Thresholds
DISK_USAGE_THRESHOLD=80   # in %
MEMORY_USAGE_THRESHOLD=80 # in %
LOAD_THRESHOLD=2.0        # CPU load threshold

# We'll store the detected distro here
DISTRO="other"

# ------------------ FUNCTIONS ------------------

log_message() {
    # Minimal logger: prints timestamp + message, also saves to LOG_FILE
    local message="$1"
    local datetime
    datetime="$(date '+%Y-%m-%d %H:%M:%S')"
    echo "${datetime} - ${message}" | tee -a "$LOG_FILE"
}

clear_log() {
    # Overwrite (clear) the log at the start of each run
    > "$LOG_FILE"
}

detect_distro() {
    # Detect Arch or Ubuntu (fallback "other")
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        case "$ID" in
            arch)
                DISTRO="arch"
                ;;
            ubuntu)
                DISTRO="ubuntu"
                ;;
            *)
                DISTRO="other"
                ;;
        esac
    fi
    # Optionally, you could parse $NAME or $PRETTY_NAME for more nuance.
    log_message "Distro detected: $DISTRO"
}

install_fastfetch_if_needed() {
    if command  fastfetch &>/dev/null; then
        # Already installed
        log_message "fastfetch is already installed."
        return 0
    fi

    # If not installed, try installing based on DISTRO
    log_message "fastfetch not found. Attempting installation..."

    case "$DISTRO" in
        "arch")
            # Arch
            if sudo pacman -Sy --noconfirm fastfetch &>/dev/null; then
                log_message "fastfetch installed successfully (pacman)."
                return 0
            else
                log_message "Failed to install fastfetch on Arch via pacman."
                return 1
            fi
            ;;
        "ubuntu")
            # Ubuntu
            # fastfetch might be in a PPA or official repos depending on version
            # Try direct install from official repos if available:
            if sudo apt-get update -y &>/dev/null && sudo apt-get install -y fastfetch &>/dev/null; then
                log_message "fastfetch installed successfully (apt-get)."
                return 0
            else
                log_message "Failed to install fastfetch on Ubuntu via apt-get."
                return 1
            fi
            ;;
        *)
            # Other distros, not supported automatically
            log_message "Unknown distro, cannot install fastfetch automatically."
            return 1
            ;;
    esac
}

display_ascii_art() {
    clear
    if command -v fastfetch &>/dev/null; then
        # We only want the ASCII art from fastfetch
        fastfetch 
        echo
    else
        # Generic fallback
        echo "==========================================="
        echo "  GENERIC HEALTH CHECK (no fastfetch)      "
        echo "==========================================="
        echo
    fi
}
check_disk_usage() {
    log_message "CHECK: Disk Usage"
    local high_mounts=()

    while read -r line; do
        # Example line from df might be:
        # /dev/sda1  55%  /home
        local usage
        usage=$(echo "$line" | awk '{print $5}' | sed 's/%//')

        local mount_point
        mount_point=$(echo "$line" | awk '{print $6}')

        # Skip if usage is empty or not an integer
        if [[ ! "$usage" =~ ^[0-9]+$ ]]; then
            continue
        fi

        # Compare usage
        if [ "$usage" -ge "$DISK_USAGE_THRESHOLD" ]; then
            high_mounts+=("$mount_point(${usage}%)")
        fi
    done < <(df -h --output=source,pcent,target | grep "^/")

    if [ ${#high_mounts[@]} -eq 0 ]; then
        log_message "RECOMMENDATION: All mounts < ${DISK_USAGE_THRESHOLD}%. No action needed."
    else
        log_message "RECOMMENDATION: High usage => ${high_mounts[*]}. Free space recommended."
    fi
}

check_cpu_load() {
    log_message "CHECK: CPU Load"
    local load
    load=$(awk '{print $1}' /proc/loadavg)
    local compare
    compare=$(awk -v val1="$load" -v val2="$LOAD_THRESHOLD" 'BEGIN {print (val1 > val2) ? 1 : 0}')

    if [ "$compare" -eq 1 ]; then
        log_message "RECOMMENDATION: Load avg $load > $LOAD_THRESHOLD. Investigate processes."
    else
        log_message "RECOMMENDATION: Load avg $load <= $LOAD_THRESHOLD. No action needed."
    fi
}

check_services() {
    log_message "CHECK: Service Status"
    local inactive=()
    for service in "${SERVICES_TO_CHECK[@]}"; do
        if ! systemctl is-active --quiet "$service"; then
            inactive+=("$service")
        fi
    done

    if [ ${#inactive[@]} -eq 0 ]; then
        log_message "RECOMMENDATION: All monitored services running."
    else
        log_message "RECOMMENDATION: Not running => ${inactive[*]}. Consider starting them."
    fi
}

check_system_updates() {
    log_message "CHECK: System Updates"
    # If distro is Arch => pacman -Qu
    # If distro is Ubuntu => apt-get
    # else => skip
    case "$DISTRO" in
        "arch")
            sudo pacman -Sy --noconfirm &>/dev/null
            local updates
            updates=$(pacman -Qu)
            if [ -n "$updates" ]; then
                local count
                count=$(echo "$updates" | wc -l)
                log_message "RECOMMENDATION: $count pkgs need updating. Run 'sudo pacman -Syu'."
            else
                log_message "RECOMMENDATION: System is up to date."
            fi
            ;;
        "ubuntu")
            sudo apt-get update -y &>/dev/null
            local upgrade_count
            upgrade_count=$(apt-get --just-print upgrade 2>/dev/null | grep "upgraded," | awk '{print $1}')
            if [[ -n "$upgrade_count" && "$upgrade_count" -gt 0 ]]; then
                log_message "RECOMMENDATION: $upgrade_count pkgs need updating. Run 'sudo apt-get upgrade'."
            else
                log_message "RECOMMENDATION: System is up to date."
            fi
            ;;
        *)
            log_message "RECOMMENDATION: Update check not implemented for $DISTRO."
            ;;
    esac
}

# ------------------ MAIN SCRIPT ------------------

# 1) Clear the old log
clear_log

# 2) Detect the distro
detect_distro

# 3) Attempt to install fastfetch if missing
install_fastfetch_if_needed

# 4) Display ASCII art (fastfetch if installed)
display_ascii_art

# 5) Log that we are starting
log_message "=== Health Check Started (Distro: $DISTRO) ==="

# 6) Perform checks (2 lines per check)
check_disk_usage
check_memory_usage
check_cpu_load
check_services
check_system_updates

log_message "=== Health Check Completed ==="

# 7) Show summary
echo
echo "---------- Health Check COMPLETE ----------"
echo " Log file: $LOG_FILE"
echo "------------------------------------------"
echo

