# 🚀 Ariel's Dotfiles (Stateless DevOps Profile)

This repository contains my personal configuration files and automation scripts tailored for a **Stateless Workstation** on **Bluefin-DX** (Fedora Atomic).

Following the **Stateless Workstation** philosophy, this setup keeps the host operating system clean and minimal, leveraging **Dev Containers** for all development work.

## 🏗 Architecture

* **OS:** Bluefin-DX (Fedora Silverblue based).
* **Host Automation:** Ansible (manages dotfiles, flatpaks, and host utilities).
* **Development:** DevPod & DevContainers (Terraform, Kubernetes, Cloud CLIs run here).
* **Productivity:** Tmux, Zoxide, Fzf, Lazygit.
* **Secrets:** Bitwarden (SSH keys injected directly into RAM, never saved to disk).

## 📂 Structure

* `ansible/` - The brain of the host setup (`setup_pc.yml`).
* `bash/` & `tmux/` - Dotfiles applied via GNU Stow.
* `scripts/legacy/` - Archived scripts from the previous Arch Linux setup.

## 🛠 Installation

To bootstrap a new machine:

1.  **Clone the repository:**
    ```bash
    mkdir -p ~/Workspace/repos
    git clone [https://github.com/ariel99gf/dotfiles.git](https://github.com/ariel99gf/dotfiles.git) ~/Workspace/repos/dotfiles
    cd ~/Workspace/repos/dotfiles
    ```

2.  **Run the Ansible Playbook:**
    ```bash
    # Full setup (including Host, NVIDIA drivers & Secure Boot MOK):
    ansible-playbook -i ansible/local/hosts.ini ansible/local/setup_pc.yml -K

    # Or run only user-space configs (Brew, dotfiles, Git):
    ansible-playbook -i ansible/local/hosts.ini ansible/local/setup_pc.yml --tags user
    ```

## 🚀 Daily Workflow

* **Start Day:** Run `unlock-ssh` to load keys from Bitwarden into RAM.
* **Work:** Navigate to a project (e.g., `homelab`) and run `devpod up .` to start a full DevOps environment.
* **Maintenance:** To update dotfiles or host configs, re-run the Ansible playbook.

## 📜 Legacy Info

The old setup based on **Arch Linux** and the monolithic `setup.sh` script has been moved to `scripts/legacy`.
