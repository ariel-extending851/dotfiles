#!/usr/bin/env bash
# ==============================================================================
# test_pc_config.sh - Automated Pre-Flight Test Suite
# Validates Ansible syntax, shell scripts, sysctl configurations, and limits.
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"

echo "================================================================="
echo "🧪 Running Pre-Flight Automated Validation Suite"
echo "Workstation: $(uname -n) | Kernel: $(uname -r)"
echo "Dotfiles Root: ${DOTFILES_DIR}"
echo "================================================================="

FAILED=0

pass() {
  echo -e "\e[32m[PASS]\e[0m $1"
}

fail() {
  echo -e "\e[31m[FAIL]\e[0m $1"
  FAILED=$((FAILED + 1))
}

info() {
  echo -e "\e[34m[INFO]\e[0m $1"
}

# 1. Syntax Check on Shell Scripts & Aliases
info "1. Validating shell script syntax..."
for f in "${DOTFILES_DIR}/bash/.bash_aliases" "${SCRIPT_DIR}/test_pc_config.sh"; do
  if [ -f "$f" ]; then
    if bash -n "$f"; then
      pass "Shell syntax check: $(basename "$f")"
    else
      fail "Shell syntax error in $f"
    fi
  fi
done

# 2. Ansible Playbook Syntax Check
info "2. Validating Ansible playbook syntax..."
if ansible-playbook -i "${DOTFILES_DIR}/ansible/local/hosts.ini" "${DOTFILES_DIR}/ansible/local/setup_pc.yml" --syntax-check >/dev/null 2>&1; then
  pass "Ansible syntax check: setup_pc.yml"
else
  fail "Ansible playbook syntax error in setup_pc.yml"
fi

# 3. Sysctl Configuration Validation against Running Kernel
info "3. Validating sysctl kernel parameters..."
validate_sysctl_file() {
  local template_file="$1"
  local name="$(basename "$template_file")"
  local errors=0

  while IFS='=' read -r key val || [ -n "$key" ]; do
    # Strip comments and whitespace
    key=$(echo "$key" | sed -e 's/#.*//' -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
    [ -z "$key" ] && continue

    # Convert dot notation to /proc/sys path
    local proc_path="/proc/sys/${key//.//}"
    if [ ! -e "$proc_path" ]; then
      fail "Kernel parameter '$key' not found at '$proc_path'"
      errors=$((errors + 1))
    fi
  done < "$template_file"

  if [ "$errors" -eq 0 ]; then
    pass "All sysctl keys exist in running kernel: $name"
  fi
}

validate_sysctl_file "${DOTFILES_DIR}/ansible/local/templates/99-devops-performance.conf.j2"
validate_sysctl_file "${DOTFILES_DIR}/ansible/local/templates/99-security-hardening.conf.j2"

# 4. Security Limits Configuration Validation
info "4. Validating security limits configuration..."
validate_limits_file() {
  local template_file="$1"
  local name="$(basename "$template_file")"
  local errors=0

  while read -r domain type item value || [ -n "$domain" ]; do
    # Skip comments and blank lines
    [[ "$domain" =~ ^#.* ]] && continue
    [ -z "$domain" ] && continue

    if [[ ! "$type" =~ ^(soft|hard|-)$ ]]; then
      fail "Invalid limit type '$type' in $name for line: $domain $type $item $value"
      errors=$((errors + 1))
    fi
    if [[ ! "$item" =~ ^(nofile|nproc|memlock|core|data|fsize|locks|stack|cpu|as)$ ]]; then
      fail "Invalid limit item '$item' in $name for line: $domain $type $item $value"
      errors=$((errors + 1))
    fi
    if ! [[ "$value" =~ ^[0-9]+$ || "$value" == "unlimited" ]]; then
      fail "Invalid limit value '$value' in $name"
      errors=$((errors + 1))
    fi
  done < "$template_file"

  if [ "$errors" -eq 0 ]; then
    pass "Security limits format valid: $name"
  fi
}

validate_limits_file "${DOTFILES_DIR}/ansible/local/templates/99-devops-limits.conf.j2"

# 5. Starship Configuration Validation
info "5. Validating Starship configuration..."
if [ -f "${DOTFILES_DIR}/starship/.config/starship.toml" ]; then
  if command -v starship &>/dev/null; then
    if starship print-config &>/dev/null; then
      pass "Starship TOML syntax is valid (verified by starship CLI)"
    else
      fail "Starship TOML configuration has syntax errors"
    fi
  else
    pass "Starship TOML exists at starship/.config/starship.toml"
  fi
fi

# 6. DevPod & Podman Pre-Flight Readiness
info "6. Checking DevPod and Podman readiness..."
if command -v podman &>/dev/null; then
  pass "Podman is installed on host ($(podman --version))"
else
  fail "Podman is missing from host"
fi

if command -v devpod &>/dev/null; then
  pass "DevPod CLI is installed on host ($(devpod version))"
else
  info "DevPod CLI will be installed via Ansible"
fi

echo "================================================================="
if [ "$FAILED" -eq 0 ]; then
  echo -e "\e[32m✨ All pre-flight tests passed successfully!\e[0m"
  echo "You are ready to run: ansible-playbook -i ansible/local/hosts.ini ansible/local/setup_pc.yml -K"
  exit 0
else
  echo -e "\e[31m❌ $FAILED pre-flight test(s) failed. Please fix issues before applying.\e[0m"
  exit 1
fi
