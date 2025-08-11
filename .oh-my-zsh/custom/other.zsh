# Disable terminal bell sound
unsetopt BEEP

# Load and initialize the completion system
# Only run compinit if not in WSL (oh-my-zsh handles it in WSL)
if [[ ! -f /proc/sys/fs/binfmt_misc/WSLInterop ]]; then
  autoload -Uz compinit
  compinit
fi