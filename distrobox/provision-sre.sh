#!/usr/bin/env bash
set -euo pipefail

echo "=========================================================="
echo "==> [SRE Toolbox] Provisionando Ambiente de Testes Fedora 44"
echo "=========================================================="

# 1. Repositórios Oficiais Externos (HashiCorp & Docker)
if [ ! -f /etc/yum.repos.d/hashicorp.repo ]; then
    echo "==> Adicionando repositório HashiCorp..."
    curl -fsSL -o /etc/yum.repos.d/hashicorp.repo https://rpm.releases.hashicorp.com/fedora/hashicorp.repo || true
fi

if [ ! -f /etc/yum.repos.d/docker-ce.repo ]; then
    echo "==> Adicionando repositório Docker CE..."
    curl -fsSL -o /etc/yum.repos.d/docker-ce.repo https://download.docker.com/linux/fedora/docker-ce.repo || true
fi

if [ ! -f /etc/yum.repos.d/google-cloud-sdk.repo ]; then
    echo "==> Adicionando repositório Google Cloud CLI..."
    tee /etc/yum.repos.d/google-cloud-sdk.repo << 'EOF'
[google-cloud-cli]
name=Google Cloud CLI
baseurl=https://packages.cloud.google.com/yum/repos/cloud-sdk-el9-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=0
gpgkey=https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOF
fi

if [ ! -f /etc/yum.repos.d/azure-cli.repo ]; then
    echo "==> Adicionando repositório Azure CLI..."
    rpm --import https://packages.microsoft.com/keys/microsoft.asc || true
    tee /etc/yum.repos.d/azure-cli.repo << 'EOF'
[azure-cli]
name=Azure CLI
baseurl=https://packages.microsoft.com/yumrepos/azure-cli
enabled=1
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc
EOF
fi

# 2. Instalação via DNF Nativo (Ferramentas Base, Linux Troubleshooting & Runtimes)
echo "==> [1/7] Instalando ferramentas essenciais e CLIs modernas via DNF..."
dnf install -y \
    git make gcc gcc-c++ jq fzf ripgrep tmux unzip wget curl zsh \
    python3 python3-pip pipx golang nodejs22 nodejs22-npm \
    neovim eza zoxide fd-find du-dust procs btop git-delta \
    ansible ansible-lint opentofu terraform packer \
    docker-ce-cli docker-compose-plugin kubernetes-client helm age \
    bind-utils nmap-ncat tcpdump strace lsof socat iperf3 sysstat iproute procps-ng \
    bubblewrap zstd lynis

# 3. Python Ecosystem: Astral 'uv' & Ferramentas
echo "==> [2/6] Configurando uv e pipx..."
if [ ! -f /usr/local/bin/uv ]; then
    curl -LsSf https://astral.sh/uv/install.sh | env UV_INSTALL_DIR="/usr/local/bin" sh || true
fi
pipx install --global pre-commit 2>/dev/null || pip install --no-cache-dir pre-commit || true
pipx install --global checkov 2>/dev/null || pip install --no-cache-dir checkov || true

# 4. Kubernetes & GitOps (Kind, K9s, ArgoCD)
echo "==> [3/6] Instalando Kubernetes & GitOps CLIs..."
# Kind (Kubernetes in Docker)
if [ ! -f /usr/local/bin/kind ]; then
    curl -Lo /usr/local/bin/kind https://kind.sigs.k8s.io/dl/v0.24.0/kind-linux-amd64 && chmod +x /usr/local/bin/kind || true
fi

# K9s
if [ ! -f /usr/local/bin/k9s ]; then
    K9S_TAG=$(curl -s https://api.github.com/repos/derailed/k9s/releases/latest | jq -r .tag_name 2>/dev/null || echo "v0.32.7")
    curl -fsSL "https://github.com/derailed/k9s/releases/download/${K9S_TAG}/k9s_Linux_amd64.tar.gz" | tar -xz -C /usr/local/bin k9s && chmod +x /usr/local/bin/k9s || true
fi

# ArgoCD CLI
if [ ! -f /usr/local/bin/argocd ]; then
    ARGO_TAG=$(curl -s https://api.github.com/repos/argoproj/argo-cd/releases/latest | jq -r .tag_name 2>/dev/null || echo "v2.12.3")
    curl -sSL -o /usr/local/bin/argocd "https://github.com/argoproj/argo-cd/releases/download/${ARGO_TAG}/argocd-linux-amd64" && chmod +x /usr/local/bin/argocd || true
fi

# 5. Segurança & Linters (Trivy, Dive, TFLint, Terragrunt, SOPS)
echo "==> [4/6] Instalando Segurança e Linters..."
# Trivy
if [ ! -f /usr/local/bin/trivy ]; then
    curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin || true
fi

# Dive
if [ ! -f /usr/local/bin/dive ]; then
    DIVE_TAG=$(curl -s https://api.github.com/repos/wagoodman/dive/releases/latest | jq -r .tag_name 2>/dev/null || echo "v0.12.0")
    curl -fsSL "https://github.com/wagoodman/dive/releases/download/${DIVE_TAG}/dive_${DIVE_TAG#v}_linux_amd64.tar.gz" | tar -xz -C /usr/local/bin dive && chmod +x /usr/local/bin/dive || true
fi

# TFLint
if [ ! -f /usr/local/bin/tflint ]; then
    curl -s https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh | bash || true
fi

# Terragrunt
if [ ! -f /usr/local/bin/terragrunt ]; then
    TG_TAG=$(curl -s https://api.github.com/repos/gruntwork-io/terragrunt/releases/latest | jq -r .tag_name 2>/dev/null || echo "v0.67.16")
    curl -fsSL -o /usr/local/bin/terragrunt "https://github.com/gruntwork-io/terragrunt/releases/download/${TG_TAG}/terragrunt_linux_amd64" && chmod +x /usr/local/bin/terragrunt || true
fi

# SOPS
if [ ! -f /usr/local/bin/sops ]; then
    SOPS_TAG=$(curl -s https://api.github.com/repos/getsops/sops/releases/latest | jq -r .tag_name 2>/dev/null || echo "v3.9.1")
    curl -fsSL -o /usr/local/bin/sops "https://github.com/getsops/sops/releases/download/${SOPS_TAG}/sops-${SOPS_TAG}.linux.amd64" && chmod +x /usr/local/bin/sops || true
fi

# Gitleaks (Secrets Detection)
if [ ! -f /usr/local/bin/gitleaks ]; then
    echo "==> Instalando Gitleaks..."
    GITLEAKS_TAG=$(curl -s https://api.github.com/repos/gitleaks/gitleaks/releases/latest | jq -r .tag_name 2>/dev/null || echo "v8.30.1")
    curl -fsSL "https://github.com/gitleaks/gitleaks/releases/download/${GITLEAKS_TAG}/gitleaks_${GITLEAKS_TAG#v}_linux_x64.tar.gz" | tar -xz -C /usr/local/bin gitleaks && chmod +x /usr/local/bin/gitleaks || true
fi

# Syft (SBOM Generation)
if [ ! -f /usr/local/bin/syft ]; then
    echo "==> Instalando Syft..."
    curl -sSfL https://raw.githubusercontent.com/anchore/syft/main/install.sh | sh -s -- -b /usr/local/bin || true
fi

# Cosign (Container Signing & Verification)
if [ ! -f /usr/local/bin/cosign ]; then
    echo "==> Instalando Cosign..."
    COSIGN_TAG=$(curl -s https://api.github.com/repos/sigstore/cosign/releases/latest | jq -r .tag_name 2>/dev/null || echo "v2.4.1")
    curl -fsSL -o /usr/local/bin/cosign "https://github.com/sigstore/cosign/releases/download/${COSIGN_TAG}/cosign-linux-amd64" && chmod +x /usr/local/bin/cosign || true
fi


# 6. Observabilidade & Testes (k6, grpcurl, act)
echo "==> [5/6] Instalando Observabilidade & Testes..."
# grpcurl
if [ ! -f /usr/local/bin/grpcurl ]; then
    GRPC_TAG=$(curl -s https://api.github.com/repos/fullstorydev/grpcurl/releases/latest | jq -r .tag_name 2>/dev/null || echo "v1.9.2")
    curl -fsSL "https://github.com/fullstorydev/grpcurl/releases/download/${GRPC_TAG}/grpcurl_${GRPC_TAG#v}_linux_x86_64.tar.gz" | tar -xz -C /usr/local/bin grpcurl && chmod +x /usr/local/bin/grpcurl || true
fi

# k6
if [ ! -f /usr/local/bin/k6 ]; then
    K6_TAG=$(curl -s https://api.github.com/repos/grafana/k6/releases/latest | jq -r .tag_name 2>/dev/null || echo "v0.54.0")
    curl -fsSL "https://github.com/grafana/k6/releases/download/${K6_TAG}/k6-${K6_TAG}-linux-amd64.tar.gz" | tar -xz --strip-components=1 -C /usr/local/bin "k6-${K6_TAG}-linux-amd64/k6" && chmod +x /usr/local/bin/k6 || true
fi

# act (GitHub Actions Local Runner)
if [ ! -f /usr/local/bin/act ]; then
    curl -s https://raw.githubusercontent.com/nektos/act/master/install.sh | bash -s -- -b /usr/local/bin || true
fi

# 7. Cloud CLIs (AWS, Google Cloud, Azure)
echo "==> [6/7] Instalando Cloud CLIs (AWS CLI v2, Google Cloud CLI, Azure CLI)..."
if [ ! -f /usr/local/bin/aws ]; then
    curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "/tmp/awscliv2.zip"
    unzip -q /tmp/awscliv2.zip -d /tmp
    /tmp/aws/install --update || true
    rm -rf /tmp/aws /tmp/awscliv2.zip
fi

dnf install -y google-cloud-cli google-cloud-cli-gke-gcloud-auth-plugin azure-cli || true

# 8. Ferramentas de Produtividade, TUIs & Starship Prompt
echo "==> [7/7] Configurando Starship, Lazygit, Lazydocker & LazyVim..."
# Starship Prompt
if [ ! -f /usr/local/bin/starship ]; then
    echo "==> Instalando Starship prompt..."
    curl -sS https://starship.rs/install.sh | sh -s -- -y -b /usr/local/bin || true
fi

# Lazygit
if [ ! -f /usr/local/bin/lazygit ]; then
    echo "==> Instalando Lazygit..."
    LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | jq -r .tag_name 2>/dev/null || echo "v0.44.1")
    curl -fsSL "https://github.com/jesseduffield/lazygit/releases/download/${LAZYGIT_VERSION}/lazygit_${LAZYGIT_VERSION#v}_Linux_x86_64.tar.gz" | tar -xz -C /usr/local/bin lazygit && chmod +x /usr/local/bin/lazygit || true
fi

# Lazydocker
if [ ! -f /usr/local/bin/lazydocker ]; then
    echo "==> Instalando Lazydocker..."
    LAZYDOCKER_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazydocker/releases/latest" | jq -r .tag_name 2>/dev/null || echo "v0.24.1")
    curl -fsSL "https://github.com/jesseduffield/lazydocker/releases/download/${LAZYDOCKER_VERSION}/lazydocker_${LAZYDOCKER_VERSION#v}_Linux_x86_64.tar.gz" | tar -xz -C /usr/local/bin lazydocker && chmod +x /usr/local/bin/lazydocker || true
fi

# LazyVim Headless Sync
echo "==> Sincronizando plugins do LazyVim..."
nvim --headless "+Lazy! sync" +qa 2>/dev/null || true

# 9. AI Ecosystem & Sandboxing (ai-jail, crush, opencode, claude, aichat, ollama, antigravity)
echo "==> [8/8] Instalando ecossistema de IA & Sandboxing..."

# ai-jail (Sandboxing para agentes autônomos por Fabio Akita)
if [ ! -f /usr/local/bin/ai-jail ]; then
    echo "==> Instalando ai-jail..."
    AI_JAIL_VERSION=$(curl -s "https://api.github.com/repos/akitaonrails/ai-jail/releases/latest" | jq -r .tag_name 2>/dev/null || echo "v1.20.3")
    curl -fsSL "https://github.com/akitaonrails/ai-jail/releases/download/${AI_JAIL_VERSION}/ai-jail-${AI_JAIL_VERSION}-x86_64-unknown-linux-musl.tar.gz" | tar -xz -C /usr/local/bin ai-jail && chmod +x /usr/local/bin/ai-jail || true
fi

# crush (Evolução oficial do OpenCode por Charmbracelet)
if [ ! -f /usr/local/bin/crush ]; then
    echo "==> Instalando crush (Charmbracelet)..."
    CRUSH_VERSION=$(curl -s "https://api.github.com/repos/charmbracelet/crush/releases/latest" | jq -r .tag_name 2>/dev/null || echo "v0.93.1")
    curl -fsSL "https://github.com/charmbracelet/crush/releases/download/${CRUSH_VERSION}/crush_${CRUSH_VERSION#v}_Linux_x86_64.tar.gz" | tar -xz -C /usr/local/bin crush && chmod +x /usr/local/bin/crush || true
fi

# opencode
if [ ! -f /usr/local/bin/opencode ]; then
    echo "==> Instalando opencode..."
    OPENCODE_VERSION=$(curl -s "https://api.github.com/repos/opencode-ai/opencode/releases/latest" | jq -r .tag_name 2>/dev/null || echo "v0.0.55")
    curl -fsSL "https://github.com/opencode-ai/opencode/releases/download/${OPENCODE_VERSION}/opencode_${OPENCODE_VERSION#v}_linux_amd64.tar.gz" | tar -xz -C /usr/local/bin opencode && chmod +x /usr/local/bin/opencode || true
fi

# Claude Code CLI (Anthropic)
if [ ! -f /usr/local/bin/claude ]; then
    echo "==> Instalando Claude Code CLI..."
    npm install -g @anthropic-ai/claude-code || true
fi

# aichat (Rust LLM CLI)
if [ ! -f /usr/local/bin/aichat ]; then
    echo "==> Instalando aichat..."
    AICHAT_VERSION=$(curl -s "https://api.github.com/repos/sigoden/aichat/releases/latest" | jq -r .tag_name 2>/dev/null || echo "v0.30.0")
    curl -fsSL "https://github.com/sigoden/aichat/releases/download/${AICHAT_VERSION}/aichat-${AICHAT_VERSION}-x86_64-unknown-linux-musl.tar.gz" | tar -xz -C /usr/local/bin aichat && chmod +x /usr/local/bin/aichat || true
fi

# Ollama CLI Client
if [ ! -f /usr/local/bin/ollama ]; then
    echo "==> Instalando Ollama CLI..."
    curl -fsSL "https://ollama.com/download/ollama-linux-amd64.tgz" | tar -xz -C /usr/local/bin bin/ollama --strip-components=1 2>/dev/null || true
    chmod +x /usr/local/bin/ollama || true
fi

# Antigravity CLI link
if [ ! -f /usr/local/bin/antigravity ]; then
    if [ -f "$HOME/.local/bin/antigravity" ]; then
        ln -sf "$HOME/.local/bin/antigravity" /usr/local/bin/antigravity
        ln -sf "$HOME/.local/bin/antigravity" /usr/local/bin/agy
    elif command -v antigravity >/dev/null 2>&1; then
        ln -sf "$(command -v antigravity)" /usr/local/bin/antigravity
        ln -sf "$(command -v antigravity)" /usr/local/bin/agy
    fi
fi

echo "=========================================================="
echo "==> [SRE Toolbox] Provisionamento concluído com sucesso!"
echo "=========================================================="

