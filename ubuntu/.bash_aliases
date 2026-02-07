alias ls="ls -lAhv --color=auto --group-directories-first"  # improved ls
alias ds="du -sh .* * 2>/dev/null"        # directory and file sizes
alias dsb="du -s .* * 2>/dev/null"        # directory and file sizes in bytes

alias ..="cd .."                          # go up one directory
alias ...="cd ../.."                      # go up two directories
alias ....="cd ../../.."                  # go up three directories

alias df="df -h"                          # human-readable disk usage
alias free="free -mh"                     # memory in MB
alias ports="sudo netstat -tulanp"        # show open ports
alias ip="ip -c a"                        # colorized ip addr

alias cls="clear"

alias s-rs="sudo systemctl restart"
alias s-start="sudo systemctl start"
alias s-stop="sudo systemctl stop"
alias s-status="sudo systemctl status"
alias nginx-test="sudo nginx -t"

alias now='date "+%Y-%m-%d %H:%M:%S"'

alias aliases="cat ~/.bash_aliases"

# Session management for tmux
tmuxx() {
  if [ -z "$1" ]; then
    # No argument provided: List sessions
    tmux ls 2>/dev/null || echo "No active sessions"
  else
    # Try to attach to the session. 
    # If it fails (doesn't exist), create it.
    tmux attach-session -t "$1" 2>/dev/null || tmux new-session -s "$1"
  fi
}
alias session='tmuxx'
