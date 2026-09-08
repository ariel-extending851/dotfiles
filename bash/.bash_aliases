# --- Activate Mise ---
if command -v mise &>/dev/null; then
  eval "$(mise activate bash)"
elif [ -x "$HOME/.local/bin/mise" ]; then
  eval "$("$HOME/.local/bin/mise" activate bash)"
elif [ -x /usr/local/bin/mise ]; then
  eval "$(/usr/local/bin/mise activate bash)"
fi

# --- Bitwarden SSH Agent ---
# Only export SSH_AUTH_SOCK if the socket exists to prevent connection errors when locked
if [ -S "$HOME/.bitwarden-ssh-agent.sock" ]; then
  export SSH_AUTH_SOCK="$HOME/.bitwarden-ssh-agent.sock"
fi

# --- Podman Rootless Socket for Docker CLI & DevPod ---
if [ -z "$DOCKER_HOST" ] && [ -S "/run/user/$(id -u)/podman/podman.sock" ]; then
  export DOCKER_HOST="unix:///run/user/$(id -u)/podman/podman.sock"
fi

# --- Backup ---
alias backup-now='sudo btrbk -c /etc/btrbk/btrbk.conf run && $HOME/backup-data-ext4.sh'

# --- SSH Key unlock ---
alias unlock-ssh='export BW_SESSION=$(bw unlock --raw) && eval $(ssh-agent -s) && bw get item Omarchy-PC | jq -r ".sshKey.privateKey" | ssh-add -'

# --- Modern Unix Tools ---

# Zoxide (cd replacement)
if command -v zoxide &>/dev/null; then
  eval "$(zoxide init bash)"
  alias cd='z'
fi

# Eza (ls replacement)
if command -v eza &>/dev/null; then
  alias ls='eza --icons --git --group-directories-first'
  alias ll='eza --icons --git --header --long --group-directories-first'
fi

# Bat (cat replacement)
if command -v bat &>/dev/null; then
  alias cat='bat'
fi

# Ripgrep (grep replacement)
if command -v rg &>/dev/null; then
  alias grep='rg'
fi

# --- DevOps & Cloud Aliases ---

# Kubernetes
alias k='kubectl'
alias kx='kubectx'
alias kn='kubens'
alias kg='kubectl get'
alias kgp='kubectl get pods'
alias kgs='kubectl get services'
alias kgd='kubectl get deployments'
alias kdp='kubectl describe pod'
alias kdd='kubectl describe deployment'
alias kdel='kubectl delete'
alias klogs='kubectl logs'
alias kex='kubectl exec -it'

# Terraform
alias tf='terraform'
alias tfi='terraform init'
alias tfp='terraform plan'
alias tfa='terraform apply'
alias tfd='terraform destroy'
alias tfo='terraform output'
alias tfv='terraform validate'

# Docker & Podman Integration
if ! command -v docker &>/dev/null && command -v podman &>/dev/null; then
  alias docker='podman'
fi
if ! command -v docker-compose &>/dev/null && command -v podman-compose &>/dev/null; then
  alias docker-compose='podman-compose'
fi
alias d='docker'
alias dc='docker compose'
alias dps='docker ps'
alias dpsa='docker ps -a'
alias di='docker images'
alias drm='docker rm'
alias drmi='docker rmi'
alias dex='docker exec -it'
alias ld='lazydocker'

# DevPod Aliases
alias dp='devpod'
alias dpu='devpod up'
alias dpd='devpod down'
alias dpp='devpod provider'

# Git (Complementing existing ones)
alias gs='git status'
alias gl='git log --oneline --graph --decorate'
alias gp='git push'
alias gpl='git pull'
alias gco='git checkout'
alias gb='git branch'
alias gd='git diff'
alias lg='lazygit'

# --- Security & Compliance ---
alias prw='prowler'
alias ckv='checkov'
alias khunt='kube-hunter'

export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

export TERM=xterm-256color

export COLORTERM=truecolor

# --- Starship Prompt ---
if command -v starship &>/dev/null; then
  eval "$(starship init bash)"
fi
