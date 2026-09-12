#!/usr/bin/env bash
# ==============================================================================
# bootstrap.sh - Zero-to-Hero Automated Workstation Bootstrap for Fedora Atomic
# Exclusively designed for rpm-ostree / Fedora Silverblue / Kinoite / Cosmic
# ==============================================================================
set -euo pipefail

# Visual styling
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

log_step() {
    echo -e "\n${CYAN}==>${NC} ${GREEN}$1${NC}"
}

log_warn() {
    echo -e "${YELLOW}[AVISO]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERRO]${NC} $1"
}

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BREW_BIN="/home/linuxbrew/.linuxbrew/bin/brew"

echo "=========================================================================="
echo "🚀 SRE Platform Engineering - Bootstrap Inicial (Fedora Atomic)"
echo "=========================================================================="

# 1. Validação de Sistema Operacional (Fedora Atomic)
log_step "[1/6] Verificando compatibilidade do sistema operacional..."
if [ ! -f /run/ostree-booted ]; then
    log_warn "O arquivo /run/ostree-booted não foi encontrado."
    log_warn "Este script é otimizado especificamente para Fedora Atomic (rpm-ostree)."
    read -rp "Deseja continuar mesmo assim? [s/N]: " continue_non_atomic
    if [[ ! "$continue_non_atomic" =~ ^[sSyY]$ ]]; then
        log_error "Bootstrap cancelado pelo usuário."
        exit 1
    fi
else
    echo "✓ Fedora Atomic detectado com sucesso."
fi

# 2. Criação de Diretórios Base do Usuário
log_step "[2/6] Preparando estrutura de diretórios base..."
mkdir -p "$HOME/Projects"
mkdir -p "$HOME/Projects/repos"
mkdir -p "$HOME/.local/bin"
mkdir -p "$HOME/.config/sops/age"
chmod 700 "$HOME/.config/sops" 2>/dev/null || true

# 3. Bootstrapping do Homebrew no Host (se não instalado)
log_step "[3/6] Verificando Homebrew no Host..."
if [ ! -x "$BREW_BIN" ]; then
    echo "Homebrew não detectado em $BREW_BIN. Iniciando instalação oficial não-interativa..."
    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

echo "✓ Carregando ambiente Homebrew na sessão atual..."
eval "$("$BREW_BIN" shellenv)"

# 4. Instalação das Ferramentas Essenciais de Bootstrap
log_step "[4/6] Instalando pacotes mínimos de bootstrap via Homebrew..."
BREW_ESSENTIALS=(
    "ansible"
    "stow"
    "mise"
    "distrobox"
    "jq"
    "bitwarden-cli"
    "tmux"
)

for tool in "${BREW_ESSENTIALS[@]}"; do
    if ! "$BREW_BIN" list --formula | grep -qx "$tool"; then
        echo "--> Instalando $tool..."
        "$BREW_BIN" install "$tool"
    else
        echo "✓ $tool já instalado no Homebrew."
    fi
done

# Garantir Mise no PATH temporário caso necessário
if [ -x "$HOME/.local/bin/mise" ]; then
    eval "$("$HOME/.local/bin/mise" activate bash 2>/dev/null || true)"
fi

# 5. Desbloqueio Opcional de Segredos via Bitwarden
echo ""
echo "--------------------------------------------------------------------------"
echo "🔐 [OPCIONAL] Desbloqueio de Chaves & Segredos (Bitwarden)"
echo "--------------------------------------------------------------------------"
echo "Se você já possui chaves SSH e o segredo SOPS gravados no Bitwarden,"
echo "desbloquear agora permitirá assinar commits e clonar seus repositórios privados."
read -rp "Deseja realizar login e desbloqueio do Bitwarden agora? [s/N]: " unlock_bw_now
if [[ "$unlock_bw_now" =~ ^[sSyY]$ ]]; then
    if ! bw login --check &>/dev/null; then
        echo "Realizando login no Bitwarden..."
        bw login
    fi
    echo "Desbloqueando cofre do Bitwarden..."
    BW_SESSION="$(bw unlock --raw)"
    export BW_SESSION
    if [ -n "$BW_SESSION" ]; then
        echo "✓ Bitwarden desbloqueado com sucesso!"
        
        # Iniciar agente SSH na memória se disponível
        if command -v ssh-agent &>/dev/null; then
            eval "$(ssh-agent -s)"
            SSH_KEY_DATA="$(bw get item "Omarchy-PC" 2>/dev/null | jq -r '.sshKey.privateKey // empty' 2>/dev/null || true)"
            if [ -n "$SSH_KEY_DATA" ]; then
                echo "$SSH_KEY_DATA" | ssh-add - 2>/dev/null && echo "✓ Chave SSH carregada na memória RAM." || true
            fi
        fi

        # Restaurar chave SOPS se existir no Bitwarden
        SOPS_KEY_DATA="$(bw get item "SOPS-Age-Key" 2>/dev/null | jq -r '.notes // empty' 2>/dev/null || true)"
        if [ -n "$SOPS_KEY_DATA" ]; then
            echo "$SOPS_KEY_DATA" > "$HOME/.config/sops/age/keys.txt"
            chmod 600 "$HOME/.config/sops/age/keys.txt"
            echo "✓ Chave SOPS Age restaurada em ~/.config/sops/age/keys.txt."
        fi
    fi
else
    echo "Pulando login do Bitwarden. Você poderá rodar 'unlock-ssh' a qualquer momento depois."
fi

# 6. Execução do Orquestrador Ansible
log_step "[5/6] Executando orquestração completa via Ansible (setup_pc.yml)..."
echo "Será solicitada a senha de 'sudo' (sudo/become pass) para aplicar o Play 1 do Host."
cd "$DOTFILES_DIR"

ansible-playbook -i ansible/local/hosts.ini ansible/local/setup_pc.yml -K

# 7. Validação de Aceitação Final (45 Asserções)
log_step "[6/6] Executando suíte automatizada de aceitação (verify.yml)..."
ansible-playbook -i ansible/local/hosts.ini ansible/local/verify.yml

echo ""
echo "=========================================================================="
echo "🎉 [SUCESSO] Bootstrap da Workstation Concluído!"
echo "=========================================================================="
echo "Resumo do ambiente preparado:"
echo "  • Host Fedora Atomic: Minimalista, Hardened (sysctl, DNSSEC/DoT, Stealth Firewall)"
echo "  • Dotfiles aplicados via GNU Stow: bash, tmux (Ctrl+a), starship, nvim (LazyVim), ssh"
echo "  • Distrobox 'sre-toolbox': Cockpit completo provisionado (40+ tools, IA, ai-jail, gitleaks)"
echo "  • DevPod & Podman: Socket rootless ativo e configurado"
echo ""
echo "👉 Para entrar imediatamente no cockpit de engenharia, digite:"
echo -e "   ${CYAN}sre${NC}  (ou 'distrobox enter sre-toolbox')"
echo ""
echo "Se foi a primeira vez que você instalou os drivers NVIDIA/MOK neste hardware,"
echo "lembre-se de reiniciar o computador ('systemctl reboot') para carregar o novo kernel."
echo "=========================================================================="
