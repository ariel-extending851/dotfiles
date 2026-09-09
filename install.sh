#!/bin/bash
# install.sh - Final robust version for DevPod

echo "🚀 Starting Personal Environment Setup..."

# 1. Ensure ~/.local/bin is in PATH for this script session
export PATH="$HOME/.local/bin:$PATH"

# 2. Install essential system tools
echo "📦 Installing system essentials (stow, curl, git)..."
sudo apt-get update && sudo apt-get install -y \
    stow \
    curl \
    git \
    libssl-dev \
    pkg-config \
    unzip \
    && sudo rm -rf /var/lib/apt/lists/*

# 3. Ensure Mise is installed
if ! command -v mise &>/dev/null; then
  echo "🛠️ Installing Mise..."
  curl https://mise.run | sh
fi

# 4. Resolve Stow conflict
# We remove the default .bash_aliases so Stow can link yours without errors
echo "🔗 Preparing symlinks..."
rm -f "$HOME/.bash_aliases"

# 5. Apply symlinks
# This links bash/.bash_aliases and mise/.config/mise/config.toml
cd "$(dirname "$0")"
stow --target="$HOME" --restow bash tmux mise starship

# 6. Install Personal Tools
# Since config.toml is now linked to ~/.config/mise/config.toml,
# Mise will pick up your tools (nvim, eza, bat, etc.) automatically.
echo "📥 Installing developer tools via Mise..."
mise trust ~/.config/mise/config.toml
mise install -y

# 7. Setup Neovim (LazyVim)
echo "🌙 Configuring Neovim (LazyVim)..."
if [ ! -d "$HOME/.config/nvim" ]; then
  echo "  Cloning LazyVim starter..."
  git clone https://github.com/LazyVim/starter "$HOME/.config/nvim"
else
  echo "  LazyVim directory already exists, skipping clone."
fi

echo "✅ Environment Ready!"
