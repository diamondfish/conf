#!/bin/bash

# Interactive installer for configuration files
# To run directly from GitHub:
# bash <(curl -fsSL https://raw.githubusercontent.com/diamondfish/conf/master/ubuntu/install_interactive_v2.sh)
# curl -fsSL https://raw.githubusercontent.com/diamondfish/conf/master/ubuntu/install.sh | bash

set -e

REPO_URL="https://raw.githubusercontent.com/diamondfish/conf/master/ubuntu"

# -----------------------------------------------------------------------------
# Options Configuration
# -----------------------------------------------------------------------------
OPTIONS=(
    "bash_aliases"  "Install .bash_aliases file"  "ON"
    "tmux"          "Install .tmux.conf file"     "ON"
)

# -----------------------------------------------------------------------------
# Installation Functions
# -----------------------------------------------------------------------------
bash_aliases_install() {
    download "$REPO_URL/.bash_aliases" ~/.bash_aliases
    source ~/.bash_aliases 2>/dev/null
}

tmux_install() {
    download "$REPO_URL/tmux/.tmux.conf" ~/.tmux.conf
}

# -----------------------------------------------------------------------------
# Whiptail Color Customization
# -----------------------------------------------------------------------------
# Set whiptail colors using NEWT_COLORS environment variable
# Format: root=,item=,
# Available colors: black, red, green, yellow, blue, magenta, cyan, white
# Available attributes: empty, bold, reverse
export NEWT_COLORS='
root=white,black
window=white,black
border=green,black
title=green,black
textbox=white,black
button=black,green
compactbutton=white,black
listbox=white,black
actlistbox=white,blue
actsellistbox=white,blue
checkbox=white,black
actcheckbox=black,green
'

# -----------------------------------------------------------------------------
# Helper Functions
# -----------------------------------------------------------------------------
download() {
    local source_url="$1"
    local target_path="$2"
    # echo "→ Downloading $source_url to $target_path"
    # if curl -fsSL "$source_url" -o "$target_path"; then
    if curl -fsSL -H "Cache-Control: no-cache" -H "Pragma: no-cache" "$source_url" -o "$target_path"; then
        # echo "✓ Download successful"
        return 0
    else
        echo "✗ Download failed: $source_url"
        # return 1
        exit 1
    fi
}

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
# WHIPTAIL_CMD=(whiptail --title "Nanto Ubuntu Configurations"
    # --checklist "\nSelect configurations to install.\nPress [SPACE] to toggle, [ENTER] to confirm and [TAB] to navigate." 20 78 ${#OPTIONS[@]})
WHIPTAIL_CMD=(whiptail --title "Nanto Ubuntu Configurations"
    --checklist "\nSelect configurations to install." 20 78 ${#OPTIONS[@]})
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

# Format choices for display (one per line)
CHOICES_FORMATTED=$(echo $CHOICES | tr ' ' '\n' | sed 's/^/  • /')

# Confirm installation
if ! whiptail --title "Confirm Installation" \
    --yesno "Install the selected configurations?\n\n$CHOICES_FORMATTED" 16 78; then
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
        echo "→ Installing '$choice' configuration..."
        # Call the installation function
        if $INSTALL_FUNC; then
            echo "✓ Done"
        else
            echo "✗ Installation failed"
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
