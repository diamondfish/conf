#!/bin/bash

# Interactive installer for configuration files
# To run directly from GitHub:
# bash <(curl -fsSL https://raw.githubusercontent.com/diamondfish/conf/master/ubuntu/install_interactive.sh)

REPO_URL="https://raw.githubusercontent.com/diamondfish/conf/master/ubuntu"

# Check if whiptail is available
if ! command -v whiptail &> /dev/null; then
    echo "Error: whiptail is not installed."
    echo "Install it with: sudo apt-get install whiptail"
    exit 1
fi

# Show checkbox menu
CHOICES=$(whiptail --title "Configuration Installer" \
    --checklist "Select configurations to install (use Space/Enter to toggle, Tab to navigate):" 20 78 4 \
    "bash_aliases" "Install .bash_aliases file" ON \
    "tmux" "Install .tmux.conf file" ON \
    3>&1 1>&2 2>&3)

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
if whiptail --title "Confirm Installation" \
    --yesno "Install the selected configurations?\n\nSelected: $CHOICES" 12 78; then
    
    echo "Installing selected configurations..."
    echo ""
    
    # Install bash_aliases if selected
    if echo $CHOICES | grep -q "bash_aliases"; then
        echo "→ Installing .bash_aliases..."
        if curl -fsSL $REPO_URL/tmux/.bash_aliases -o ~/.bash_aliases; then
            echo "✓ Installed ~/.bash_aliases"
            source ~/.bash_aliases 2>/dev/null
        else
            echo "✗ Failed to install .bash_aliases"
        fi
    fi
    
    # Install tmux if selected
    if echo $CHOICES | grep -q "tmux"; then
        echo "→ Installing .tmux.conf..."
        if curl -fsSL $REPO_URL/tmux/.tmux.conf -o ~/.tmux.conf; then
            echo "✓ Installed ~/.tmux.conf"
        else
            echo "✗ Failed to install .tmux.conf"
        fi
    fi
    
    echo ""
    echo "Installation complete!"
    
    if echo $CHOICES | grep -q "tmux"; then
        echo "Note: Restart tmux sessions for .tmux.conf changes to take effect"
    fi
else
    echo "Installation cancelled."
    exit 0
fi
