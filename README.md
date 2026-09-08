# 🚀 Ariel's Dotfiles & SRE Platform Engineering

[![CI / IaC Quality & Molecule Testing](https://github.com/ariel99gf/dotfiles/actions/workflows/ci.yml/badge.svg)](https://github.com/ariel99gf/dotfiles/actions/workflows/ci.yml)
[![Ansible](https://img.shields.io/badge/Ansible-2.14%2B-red.svg?logo=ansible)](https://docs.ansible.com/)
[![Molecule](https://img.shields.io/badge/Tested%20with-Molecule-blue.svg?logo=ansible)](https://molecule.readthedocs.io/)
[![Fedora Atomic](https://img.shields.io/badge/OS-Fedora%20Atomic-blue.svg?logo=fedora)](https://fedoraproject.org/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

This repository contains my personal infrastructure-as-code automation and dotfiles, built following **SRE (Site Reliability Engineering)**, **Platform Engineering**, and **Stateless Workstation** principles on **Fedora Atomic (rpm-ostree / COSMIC Atomic)**.

---

## 🏗 Architecture & Design Philosophy

1. **Stateless Workstation:** The physical host OS remains minimal, secure, and reproducible. Heavy cloud SDKs, Terraform, and Kubernetes runtimes live inside isolated containers managed by **DevPod** and **DevContainers**.
2. **Modular IaC Roles:** System performance and security configurations are componentized into reusable Ansible roles (`ansible/roles/system_tuning`).
3. **Shift-Left Testing (SRE Pyramid):**
   - **Static Analysis:** `ansible-lint` enforces IaC best practices and security.
   - **Integration & Idempotency:** **Molecule** tests roles in ephemeral Podman/Docker containers, guaranteeing that secondary runs result in zero unexpected state drift (`changed: 0`).
   - **Host Deep Verification:** `ansible/local/verify.yml` and `./test` run strict assertions against live hardware, Secure Boot, sockets, and CLI tooling.
4. **Modern DevEx (Developer Experience):** Unified task orchestration via **Mise** (`mise run test`, `mise run molecule`, `mise run verify`).

---

## 📂 Repository Structure

```text
├── .github/workflows/ci.yml       # Automated CI/CD pipeline (Lint + Molecule)
├── .ansible-lint                  # Quality & security linting rules
├── .mise.toml                     # Platform task orchestration
├── test                           # Fast test runner symlink (Python 3)
├── scripts/tests/test_pc.py       # Pre-flight and SRE assertion test engine
├── ansible/
│   ├── local/
│   │   ├── setup_pc.yml           # Host orchestrator (Hardware, OSTree, DevPod)
│   │   ├── verify.yml             # Live host acceptance testing (Asserts)
│   │   └── hosts.ini              # Local connection inventory
│   └── roles/
│       └── system_tuning/         # Modular SRE performance & hardening role
│           ├── defaults/main.yml  # Configurable sysctl & limits parameters
│           ├── tasks/main.yml     # Role execution logic
│           ├── templates/         # Parametrized sysctl & limits templates
│           └── molecule/default/  # Molecule lifecycle & idempotency scenario
├── bash/                          # Shell configuration & aliases (GNU Stow)
├── starship/                      # SRE-tuned cross-shell prompt (GNU Stow)
└── tmux/                          # Terminal multiplexer configuration (GNU Stow)
```

---

## 🧪 Testing & Quality Assurance (SRE Showcase)

This repository features automated multi-layer testing:

### 1. Pre-Flight & Syntax Validation
Run fast pre-flight syntax and kernel compatibility tests:
```bash
./test --pre
# or using Mise:
mise run test:syntax
```

### 2. Molecule Role Testing (Idempotence & State)
Test the `system_tuning` role in an isolated container with full lifecycle and idempotency verification:
```bash
cd ansible/roles/system_tuning
molecule test
# or using Mise:
mise run test:molecule
```

### 3. Deep Host Verification (Live Assertions)
Verify that the physical host matches the desired state (Kernel sysctl, Podman socket, DevPod provider, Secure Boot, NVIDIA GPU acceleration, Stow symlinks):
```bash
./test --verify
# or using Mise:
mise run verify
```

### 4. Run Everything in One Command
```bash
./test
# or using Mise:
mise run test
```

---

## 🚀 Bootstrap & Usage

### 1. Quick Bootstrap
```bash
# Clone the repository
git clone https://github.com/ariel99gf/dotfiles.git ~/Projects/dotfiles
cd ~/Projects/dotfiles

# Run pre-flight automated tests
./test --pre

# Apply host & user configurations:
ansible-playbook -i ansible/local/hosts.ini ansible/local/setup_pc.yml -K
```

### 2. Daily Workflow (DevEx with Mise)
```bash
# Apply dotfiles and user configurations:
mise run apply

# Validate system health and SRE compliance:
mise run verify
```
