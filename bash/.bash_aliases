# --- Activate Mise ---
if command -v mise &>/dev/null; then
  eval "$(mise activate bash)"
elif [ -x "$HOME/.local/bin/mise" ]; then
  eval "$("$HOME/.local/bin/mise" activate bash)"
elif [ -x /usr/local/bin/mise ]; then
  eval "$(/usr/local/bin/mise activate bash)"
fi

# --- Bitwarden SSH Agent ---
export SSH_AUTH_SOCK="$HOME/.bitwarden-ssh-agent.sock"

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

# Docker
alias d='docker'
alias dc='docker compose'
alias dps='docker ps'
alias dpsa='docker ps -a'
alias di='docker images'
alias drm='docker rm'
alias drmi='docker rmi'
alias dex='docker exec -it'

# Git (Complementing existing ones)
alias gs='git status'
alias gl='git log --oneline --graph --decorate'
alias gp='git push'
alias gpl='git pull'
alias gco='git checkout'
alias gb='git branch'
alias gd='git diff'

# --- Security & Compliance ---
alias prw='prowler'
alias ckv='checkov'
alias khunt='kube-hunter'

export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

export TERM=xterm-256color

export COLORTERM=truecolor
