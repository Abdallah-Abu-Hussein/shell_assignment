#!/usr/bin/env bash
#
# interactive_backup_spinner.sh
# Description:
#   1. Displays ASCII art as a welcome banner.
#   2. Asks the user to enter multiple directories (one by one) using tab-completion.
#   3. Expands tilde (~) paths automatically.
#   4. Prompts for a backup destination directory.
#   5. Shows a loading spinner while creating a compressed tar archive.
#   6. Logs all actions and any errors.

# ------------------ CONFIGURATION ------------------
LOG_FILE="/var/log/interactive_backup.log"

# Current date/time stamp for naming the archive
TIMESTAMP="$(date +%F_%H%M%S)"
ARCHIVE_NAME="backup_${TIMESTAMP}.tar.gz"

# Array to store user-specified directories
declare -a DIRECTORIES_TO_BACKUP=()

# ------------------ FUNCTIONS ------------------

# 1) LOGGING
log_message() {
    local message="$1"
    local datetime
    datetime="$(date '+%Y-%m-%d %H:%M:%S')"
    echo "${datetime} - ${message}" | tee -a "$LOG_FILE"
}

# 2) PATH EXPANSION
expand_path() {
    # Use 'eval echo' to expand ~ and variables if present
    local input_path="$1"
    local expanded_path
    expanded_path="$(eval echo "${input_path}")"
    echo "$expanded_path"
}

# 3) SPINNER
spinner() {
    # A simple spinner that runs while a background process is active.
    local pid=$!         # PID of the last background command
    local delay=0.1      # Seconds between spinner updates
    local spinstr='|/-\'
    while kill -0 "$pid" 2>/dev/null; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        spinstr=$temp${spinstr%"$temp"}
        sleep "$delay"
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}

# 4) CREATE BACKUP ARCHIVE
create_backup_archive() {
    local destination="$1"
    local archive_path="$destination/$ARCHIVE_NAME"

    log_message "Starting backup of directories: ${DIRECTORIES_TO_BACKUP[*]}"
    log_message "Creating archive at: $archive_path"

    # --- Run the tar command in the background; show spinner while it runs ---
    (
        tar -czf "$archive_path" "${DIRECTORIES_TO_BACKUP[@]}" 2>>"$LOG_FILE"
    ) &
    spinner  # Display spinner until tar finishes

    # Check if tar succeeded
    if [ $? -ne 0 ]; then
        log_message "ERROR: Failed to create backup archive."
        exit 1
    fi
    log_message "Backup archive successfully created."

    # Show final archive size
    local size
    size=$(du -sh "$archive_path" | awk '{print $1}')
    log_message "Backup archive size: $size"
}

# 5) CHECK AND CREATE DESTINATION
check_and_create_destination() {
    local destination="$1"
    if [ ! -d "$destination" ]; then
        mkdir -p "$destination" 2>>"$LOG_FILE"
        if [ $? -ne 0 ]; then
            log_message "ERROR: Failed to create backup destination: $destination"
            exit 1
        fi
        log_message "Created backup destination directory: $destination"
    fi
}

# 6) ASCII ART BANNER
display_banner() {
    clear
    echo "================================================================="
    echo "================================================================="
    echo "      WELCOME TO THE Atypon Assignment INTERACTIVE BACKUP SCRIPT"
    echo "================================================================="
    echo "================================================================="
}

# ------------------ MAIN SCRIPT ------------------

# Display the banner
display_banner

# Prompt user to enter one or more directories, enabling TAB completion with read -e
echo "Please enter directories to include in the backup, one by one."
echo "Use TAB to auto-complete directory names."
echo "Leave the input blank (press [Enter]) when finished."

while true; do
    read -e -rp "Directory path (press [Enter] if done): " dir_input

    # Check if user pressed Enter with no input => done adding directories
    if [ -z "$dir_input" ]; then
        break
    fi

    # Expand tilde or environment variables
    dir_input_expanded="$(expand_path "$dir_input")"

    # Validate the directory
    if [ ! -d "$dir_input_expanded" ]; then
        echo "ERROR: '$dir_input_expanded' is not a valid directory. Please try again."
        continue
    fi

    # Store the directory
    DIRECTORIES_TO_BACKUP+=("$dir_input_expanded")
    echo "Added: $dir_input_expanded"
done

# Check if at least one directory was added
if [ ${#DIRECTORIES_TO_BACKUP[@]} -eq 0 ]; then
    echo "No directories were provided. Exiting..."
    exit 1
fi

# Prompt user for the backup destination, also enabling tab-completion
echo ""
echo "Now, please specify the directory where you'd like to place the backup."
read -e -rp "Backup destination (e.g., /home/user/backups): " BACKUP_DEST

# Expand potential tilde in the destination path
BACKUP_DEST="$(expand_path "$BACKUP_DEST")"

if [ -z "$BACKUP_DEST" ]; then
    echo "No backup destination entered. Exiting..."
    exit 1
fi

# Validate or create destination
check_and_create_destination "$BACKUP_DEST"

# Confirm before proceeding
echo ""
echo "You have specified the following directories for backup:"
printf '  * %s\n' "${DIRECTORIES_TO_BACKUP[@]}"
echo ""
echo "Backup archive will be created in: $BACKUP_DEST"
read -rp "Press [Enter] to start the backup or Ctrl+C to cancel..." _

# Perform the backup (with spinner)
create_backup_archive "$BACKUP_DEST"

# Done
echo ""
log_message "Backup script completed successfully."
echo "Backup process finished. Check $LOG_FILE for details."
exit 0

