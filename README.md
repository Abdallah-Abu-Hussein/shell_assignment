# Combined Documentation for Backup & Health Check Scripts

This document provides **comprehensive documentation** for two Bash scripts:

1. **Interactive Backup Script**

   - Prompts you for directories to back up (one at a time).
   - Supports tilde expansion (`~`) and tab completion.
   - Creates a timestamped `.tar.gz` archive.
   - Logs progress in `/var/log/interactive_backup.log`.

2. **Health Check Script**

   - Detects Arch/Ubuntu (with fallback “other”).
   - Installs `fastfetch` automatically on Arch/Ubuntu, displaying ASCII art.
   - Checks disk usage, memory, CPU load, service statuses, and updates.
   - Logs concise results in `/var/log/health_check.log`.

Both are **standalone** tools that help automate common system tasks. You can run them independently or schedule them (e.g., via cron).

---

## Table of Contents

1. [Overview](#overview)
2. [Features](#features)
   - [Backup Script](#backup-script-features)
   - [Health Check Script](#health-check-script-features)
3. [Prerequisites & Requirements](#prerequisites--requirements)
4. [Installation & Setup](#installation--setup)
5. [Usage](#usage)
   - [Backup Script](#backup-script-usage)
   - [Health Check Script](#health-check-script-usage)
6. [Configuration](#configuration)
   - [Backup Script](#backup-script-configuration)
   - [Health Check Script](#health-check-script-configuration)
7. [Troubleshooting & Common Issues](#troubleshooting--common-issues)
8. [Extending or Customizing](#extending-or-customizing)
9. [License](#license)

---

## Overview

### Interactive Backup Script

An **interactive** approach to directory backups:

- Asks you to **enter multiple directory paths**.
- Waits until you press Enter on an **empty prompt** to finalize the list.
- **Tab completion** (via `read -e`) so you can quickly navigate files and directories.
- **Tilde expansion** automatically converts `~` to `/home/username`.
- Builds a `.tar.gz` archive named with the current date/time, e.g. `backup_2025-01-25_120002.tar.gz`.
- Logs to **`/var/log/interactive_backup.log`**.

This script suits **user-friendly backups** where you can decide exactly which directories to include on-the-fly.

### Health Check Script

A **compact** system auditing script:

- Detects if the system is **Arch Linux** or **Ubuntu** (via `/etc/os-release`).
- If on Arch/Ubuntu and `fastfetch` is missing, **installs it** automatically.
- **Displays ASCII art** for your distro using `fastfetch` (or a generic fallback otherwise).
- **Checks**:
  - **Disk usage** (skipping invalid lines to avoid “integer expression” errors),
  - **Memory usage**,
  - **CPU load**,
  - **Service statuses** (like `sshd`, `cron`),
  - **System updates** (via `pacman -Qu` or `apt-get --just-print upgrade`).
- Logs **two-line** summaries per check to **`/var/log/health_check.log`** and **prints** the log at the end.

Great for **quick insight** into your system’s health without a bulky overhead.

---

## Features

### Backup Script Features

1. **Interactive Directory Input**

   - Enter as many directories as you want.
   - Press Enter on an empty prompt to finish.

2. **Tilde Expansion & Tab Completion**

   - `read -e` for Bash line editing.
   - Expands `~` so you can type `~/Documents` etc.

3. **Compression**

   - Creates a `.tar.gz` with a timestamp-based filename.

4. **Logging**

   - Logs each significant step to `/var/log/interactive_backup.log` (defaults).
   - Reports errors and the final archive size.

5. **Optional ASCII/Spinner**

   - Can use a variant with a loading spinner or ASCII banner if desired.

### Health Check Script Features

1. **Automatic ********`fastfetch`******** Install** (Arch/Ubuntu)

   - If missing, tries `pacman` on Arch or `apt-get` on Ubuntu.

2. **ASCII Art**

   - Uses `fastfetch --logo-only` to show distro-specific art.
   - Fallback generic banner if not supported.

3. **System Checks**

   - **Disk usage**: Skips non-numeric usage lines, preventing integer errors.
   - **Memory usage**: Compares used mem vs. threshold.
   - **CPU load**: Compares 1-min average vs. threshold.
   - **Services**: Checks `systemctl` status for a given list.
   - **Updates**: `pacman -Qu` on Arch, `apt-get` on Ubuntu, or “not implemented” for others.

4. **Two-Line Logging Per Check**

   - For each check:
     1. `CHECK: <Name>`
     2. `RECOMMENDATION: <Action or summary>`

5. **Auto Log Display**

   - Prints `/var/log/health_check.log` after completing so you see everything at once.

---

## Prerequisites & Requirements

### Both Scripts

1. **Bash Shell**

   - Uses arrays, `read -e`, expansions, etc. Not guaranteed to work under `sh` or other shells.

2. **Permissions**

   - If you want to read system directories for backup or do system update checks, you likely need `sudo`.
   - Logging to `/var/log/` usually requires root privileges.

3. **Tar & Gzip** (for the backup script)

   - Normally pre-installed on Linux systems.

4. \*\*`df`\*\*\*\*, ****`free`****, ****`awk`****, ****`systemctl`****, \*\***`grep`** (for the health check)

   - Typically standard on most distros.

### Additional for Health Check

- If you want **auto-install** of `fastfetch`:
  - **Arch**: `pacman` must be available.
  - **Ubuntu**: `apt-get` is needed.
- On other distros, the script tries a fallback approach or simply logs “not implemented”.

---

## Installation & Setup

1. **Obtain the Scripts**

   - Download/clone from your repository:
     - `interactive_backup.sh`
     - `health_check_fastfetch_installer.sh` (or your chosen naming/variant).

2. **Make Them Executable**

   ```bash
   chmod +x backup.sh
   chmod +x checkHealth.sh
   ```

3. **(Optional) Move to a System Path**

   ```bash
   sudo cp backup.sh /usr/local/bin/interactive_backup
   sudo cp checkHealth.sh /usr/local/bin/health_check
   ```

   - Now you can run `interactive_backup` or `health_check` without specifying the path.

4. **Verify**

   - **Backup Script**: `./interactive_backup.sh` → Should prompt for directories.
   - **Health Check**: `./health_check_fastfetch_installer.sh` → Should detect distro, maybe install `fastfetch`.

---

## Usage

### Backup Script Usage

1. **Run**

   ```bash
   ./backup.sh
   ```

   or

   ```bash
   sudo ./backup.sh
   ```

   if you’re backing up root-only directories.

2. **Enter Directories**

   - Type a directory path, press Enter.
   - Repeat for additional directories.
   - Press Enter on an **empty prompt** to finalize.

3. **Specify Destination**

   - Example: `/home/user/backups`.
   - The script creates this directory if missing.

4. **Confirm**

   - Shows the directories you selected and the destination.
   - Press Enter to proceed or `Ctrl+C` to cancel.

5. **Archive Creation**

   - Tars and gzips everything into `backup_<timestamp>.tar.gz` in your chosen destination.
   - Logs progress in `/var/log/interactive_backup.log`.

6. **Completion**

   - Reports success, logs final archive size.
   - You can check `/var/log/interactive_backup.log` for full details.

### Health Check Script Usage

1. **Run**

   ```bash
   ./checkHealth.sh
   ```

   or

   ```bash
   sudo ./chcheckHealth.sh
   ```
   (sudo recommended if you want to install `fastfetch` or run system updates.)

2. \*\*Auto-Install \*\***`fastfetch`**

   - If on Arch/Ubuntu and `fastfetch` is missing, the script attempts to install it.
   - Otherwise, uses a generic ASCII banner.

3. **Checks**

   - The script sequentially checks disk usage, memory usage, CPU load, services, and system updates.
   - Logs each check to `/var/log/health_check.log`.

4. **Final Log**

   - After finishing, it prints the entire log to your console.
   - You can also inspect `/var/log/health_check.log` later.

---

## Configuration

### Backup Script Configuration

- **`LOG_FILE`**

  - Default: `/var/log/interactive_backup.log`.
  - Change in the script if you prefer a different location (or no root usage).

- **Archive Name Pattern**

  - Default: `backup_YYYY-MM-DD_HHMMSS.tar.gz`.
  - You can edit the `TIMESTAMP` and `ARCHIVE_NAME` variables.

- **Cleanup**

  - If you want to delete old backups automatically, add something like:
    ```bash
    find "$BACKUP_DEST" -name "backup_*.tar.gz" -mtime +7 -exec rm -f {} \;
    ```
  - e.g., remove backups older than 7 days.

### Health Check Script Configuration

- **`LOG_FILE`**

  - Default: `/var/log/health_check.log`.

- **Thresholds**

  - **`DISK_USAGE_THRESHOLD`** (default 80%).
  - **`MEMORY_USAGE_THRESHOLD`** (default 80%).
  - **`LOAD_THRESHOLD`** (default 2.0).

- **Services**

  - `SERVICES_TO_CHECK=( "sshd" "cron" )`.
  - Modify or expand for your environment.

- **Package Manager**

  - The script checks `$DISTRO` via `/etc/os-release`:
    - If `arch`, uses `pacman`.
    - If `ubuntu`, uses `apt-get`.
    - Else logs “Update check not implemented.”
  - Extend it if you need other distros.

---

## Troubleshooting & Common Issues

1. **Integer Expression Errors**

   - Typically caused by lines that don’t have a numeric usage in disk checks.
   - Latest script versions skip any mount lines missing numeric usage, so be sure you have the updated version.

2. **Permission Denied**

   - If logging to `/var/log/...`, creating backups in restricted directories, or installing packages, you might need `sudo`.

3. **fastfetch Installation Fails** (Health Check)

   - On non-Arch/Ubuntu distros or if your repo doesn’t have `fastfetch`.
   - Install it manually or remove the auto-install logic.

4. **Tab Completion Not Working** (Backup Script)

   - Ensure you’re using Bash with standard completions loaded. By default, `read -e` should allow arrow keys and tab expansions.

5. **No Services Found** (Health Check)

   - If a service isn’t installed or named differently on your distro, the script logs “ERROR: Service not found.”
   - Update `SERVICES_TO_CHECK`.

6. **Large Backups**

   - If you’re backing up huge directories, `tar` might take a long time.
   - A spinner variant can show progress. Otherwise, consider advanced backup tools (e.g., `borgbackup` or `rsync`) for incremental backups.

---

## Extending or Customizing

1. **Encryption**

   - Pipe the final `.tar.gz` through `gpg` or `openssl` for secure backups.

2. **Remote Sync**

   - After archive creation, upload to a remote server with `scp`, `rsync`, or a cloud CLI.

3. **Incremental/Versioned Backups**

   - Combine with other solutions if you need versioning or deduplication.

4. **Additional Health Checks**

   - CPU temperature, container statuses, kernel logs, disk I/O, etc.

5. **Scheduling**

   - Use `cron` to automate daily/weekly runs. For example:
     ```bash
     sudo crontab -e
     # Run backup script daily at 2 AM
     0 2 * * * /usr/local/bin/interactive_backup
     # Run health check daily at 3 AM
     0 3 * * * /usr/local/bin/health_check
     ```

6. **Notifications**

   - Email or Slack/Webhook alerts if disk usage is too high or backups fail.

---



