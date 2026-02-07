#!/bin/bash

# To install, run this command:
# curl -fsSL https://raw.githubusercontent.com/diamondfish/conf/master/ubuntu/install.sh | bash

REPO_URL="https://raw.githubusercontent.com/diamondfish/conf/master/ubuntu"

curl -fsSL $REPO_URL/.bash_aliases -o ~/.bash_aliases
curl -fsSL $REPO_URL/tmux/.tmux.conf -o ~/.tmux.conf

source ~/.bash_aliases
