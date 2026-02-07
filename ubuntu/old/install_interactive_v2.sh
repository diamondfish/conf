#!/bin/bash

# Interactive installer for configuration files
# To run directly from GitHub:
# bash <(curl -fsSL https://raw.githubusercontent.com/diamondfish/conf/master/ubuntu/install_interactive_v2.sh)

REPO_URL="https://raw.githubusercontent.com/diamondfish/conf/master/ubuntu"

# -----------------------------------------------------------------------------
# Helper Functions
# -----------------------------------------------------------------------------

# Download a file from URL to target location
# Usage: download_file <source_url> <target_path> [display_name]
download_file() {
    local source_url="$1"
    local target_path="$2"
    # local display_name="${3:-$target_path}"
    
    echo "→ Installing $display_name..."
    if curl -fsSL "$source_url" -o "$target_path"; then
        echo "✓ Installed $target_path"
        return 0
    else
        # echo "✗ Failed to install $display_name"
        echo "✗ Installation failed"
        return 1
    fi
}

# -----------------------------------------------------------------------------
# Installation Functions - Add new installations here
# -----------------------------------------------------------------------------

bash_aliases_install() {
    download_file "$REPO_URL/tmux/.bash_aliases" ~/.bash_aliases && \
    source ~/.bash_aliases 2>/dev/null
}

tmux_install() {
    download_file "$REPO_URL/tmux/.tmux.conf" ~/.tmux.conf
    # if download_file "$REPO_URL/tmux/.tmux.conf" ~/.tmux.conf; then
    #     echo "  Note: Restart tmux sessions for changes to take effect"
    #     return 0
    # fi
    # return 1
}

# -----------------------------------------------------------------------------
# Options Configuration - Add new options here
# -----------------------------------------------------------------------------

# Define available options (format: "id" "description" "default_state")
OPTIONS=(
    "bash_aliases" "Install .bash_aliases file" "ON"
    "tmux" "Install .tmux.conf file" "ON"
)

# -----------------------------------------------------------------------------
# Main Installation Logic
# -----------------------------------------------------------------------------

# Check if whiptail is available
if ! command -v whiptail &> /dev/null; then
    echo "Error: whiptail is not installed."
    echo "Install it with: sudo apt-get install whiptail"
    exit 1
fi

# Build whiptail command from OPTIONS array
WHIPTAIL_CMD=(whiptail --title "Configuration Installer"
    --checklist "Select configurations to install (Space/Enter to toggle, Tab to navigate):" 20 78 ${#OPTIONS[@]})
WHIPTAIL_CMD+=("${OPTIONS[@]}")

# Show checkbox menu
CHOICES=$("${WHIPTAIL_CMD[@]}" 3>&1 1>&2 2>&3)

# Check if user cancelled
if [ $? -ne 0 ]; then
    echo "Installation cancelled."
    exit 0
fi

# Remove quotes from the result
CHOICES=$(echo $CHOICES | tr -d '"')

# Check if any options were selected
if [ -z "$CHOICES" ]; then
    echo "No options selected. Exiting."
    exit 0
fi

# Confirm installation
if ! whiptail --title "Confirm Installation" \
    --yesno "Install the selected configurations?\n\nSelected: $CHOICES" 12 78; then
    echo "Installation cancelled."
    exit 0
fi

echo "Installing selected configurations..."
echo ""

# Process each selected option
FAILED_COUNT=0
for choice in $CHOICES; do
    # Check if the installation function exists
    INSTALL_FUNC="${choice}_install"
    if declare -f "$INSTALL_FUNC" > /dev/null; then
        # Call the installation function
        if ! $INSTALL_FUNC; then
            FAILED_COUNT=$((FAILED_COUNT + 1))
        fi
    else
        echo "⚠ Warning: No installation function found for '$choice'"
        FAILED_COUNT=$((FAILED_COUNT + 1))
    fi
    echo ""
done

# Summary
if [ $FAILED_COUNT -eq 0 ]; then
    echo "✓ Installation complete! All configurations installed successfully."
    exit 0
else
    echo "⚠ Installation completed with $FAILED_COUNT error(s)."
    exit 1
fi
