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
