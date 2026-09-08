#!/usr/bin/env python3
"""
test_pc.py - SRE Workstation Validation & Testing Suite
Pure Python 3 Standard Library - Zero external dependencies.
"""
import argparse
import os
import pathlib
import subprocess
import sys

GREEN = "\033[32m"
RED = "\033[31m"
BLUE = "\033[34m"
RESET = "\033[0m"

DOTFILES_DIR = pathlib.Path(__file__).resolve().parent.parent.parent


def log_pass(msg: str):
    print(f"{GREEN}[PASS]{RESET} {msg}")


def log_fail(msg: str):
    print(f"{RED}[FAIL]{RESET} {msg}")


def log_info(msg: str):
    print(f"{BLUE}[INFO]{RESET} {msg}")


class TestRunner:
    def __init__(self):
        self.failed = 0

    def run_preflight(self):
        print("=" * 65)
        print("🧪 Running SRE Pre-Flight Quality & Syntax Checks")
        print(f"Workstation: {os.uname().nodename} | Kernel: {os.uname().release}")
        print(f"Dotfiles Root: {DOTFILES_DIR}")
        print("=" * 65)

        # 1. Shell Syntax
        log_info("1. Validating shell scripts syntax...")
        aliases_file = DOTFILES_DIR / "bash/.bash_aliases"
        if aliases_file.exists():
            res = subprocess.run(["bash", "-n", str(aliases_file)])
            if res.returncode == 0:
                log_pass("Shell syntax check: .bash_aliases")
            else:
                log_fail("Syntax error in .bash_aliases")
                self.failed += 1

        # 2. Ansible Playbooks Syntax Check
        log_info("2. Validating Ansible playbook syntax...")
        for playbook in ["setup_pc.yml", "verify.yml"]:
            pb_path = DOTFILES_DIR / "ansible/local" / playbook
            res = subprocess.run(
                [
                    "ansible-playbook",
                    "-i",
                    str(DOTFILES_DIR / "ansible/local/hosts.ini"),
                    str(pb_path),
                    "--syntax-check",
                ],
                capture_output=True,
                text=True,
            )
            if res.returncode == 0:
                log_pass(f"Ansible syntax check: {playbook}")
            else:
                log_fail(f"Ansible syntax error in {playbook}: {res.stderr}")
                self.failed += 1

        # 3. Kernel Sysctl Parameters check in running kernel
        log_info("3. Validating sysctl kernel parameters compatibility...")
        sysctl_templates = [
            DOTFILES_DIR / "ansible/roles/system_tuning/templates/99-devops-performance.conf.j2",
            DOTFILES_DIR / "ansible/roles/system_tuning/templates/99-security-hardening.conf.j2",
        ]
        for tmpl in sysctl_templates:
            if not tmpl.exists():
                log_fail(f"Template not found: {tmpl}")
                self.failed += 1
                continue
            errors = 0
            for line in tmpl.read_text().splitlines():
                line = line.split("#")[0].strip()
                if not line or "=" not in line:
                    continue
                key = line.split("=")[0].strip()
                proc_path = pathlib.Path("/proc/sys") / key.replace(".", "/")
                if not proc_path.exists():
                    log_fail(f"Kernel key not found at {proc_path}")
                    errors += 1
            if errors == 0:
                log_pass(f"All sysctl keys exist in running kernel: {tmpl.name}")
            else:
                self.failed += errors

        # 4. Starship Config Validation
        log_info("4. Validating Starship configuration...")
        starship_cfg = DOTFILES_DIR / "starship/.config/starship.toml"
        if starship_cfg.exists():
            res = subprocess.run(["starship", "print-config"], capture_output=True)
            if res.returncode == 0:
                log_pass("Starship TOML syntax is valid (verified by starship CLI)")
            else:
                log_fail("Starship TOML configuration error")
                self.failed += 1

        # 5. Podman & DevPod CLI
        log_info("5. Checking Podman and DevPod readiness...")
        res_podman = subprocess.run(["podman", "--version"], capture_output=True, text=True)
        if res_podman.returncode == 0:
            log_pass(f"Podman is installed ({res_podman.stdout.strip()})")
        else:
            log_fail("Podman is not installed")
            self.failed += 1

        res_devpod = subprocess.run(["devpod", "version"], capture_output=True, text=True)
        if res_devpod.returncode == 0:
            log_pass(f"DevPod CLI is installed ({res_devpod.stdout.strip()})")
        else:
            log_fail("DevPod is not installed")
            self.failed += 1

    def run_verification(self):
        print("\n" + "=" * 65)
        print("🔍 Running Deep Host Verification Suite (Ansible Assert)")
        print("=" * 65)
        verify_pb = DOTFILES_DIR / "ansible/local/verify.yml"
        hosts_ini = DOTFILES_DIR / "ansible/local/hosts.ini"
        res = subprocess.run(["ansible-playbook", "-i", str(hosts_ini), str(verify_pb)])
        if res.returncode == 0:
            log_pass("Host verification completed with 100% assertions valid!")
        else:
            log_fail("Host verification assertions failed!")
            self.failed += 1


def main():
    parser = argparse.ArgumentParser(description="SRE Workstation Automated Test Suite")
    parser.add_argument("--pre", action="store_true", help="Run only pre-flight checks")
    parser.add_argument(
        "--verify", action="store_true", help="Run only host verification assertions"
    )
    args = parser.parse_args()

    runner = TestRunner()

    if args.pre:
        runner.run_preflight()
    elif args.verify:
        runner.run_verification()
    else:
        runner.run_preflight()
        runner.run_verification()

    print("\n" + "=" * 65)
    if runner.failed == 0:
        print(f"{GREEN}✨ All tests passed successfully! System is fully operational.{RESET}")
        sys.exit(0)
    else:
        print(f"{RED}❌ {runner.failed} test(s) failed. Please check the logs above.{RESET}")
        sys.exit(1)


if __name__ == "__main__":
    main()
