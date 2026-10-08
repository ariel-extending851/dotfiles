#!/usr/bin/env bash
# ==============================================================================
# bitcoin-luks.sh - Sovereign Full Node LUKS2 Cold Vault Manager (Option A)
# ==============================================================================
set -euo pipefail

MAPPER_NAME="bitcoin-crypt"
DEV_PART="/dev/sdc1"
MOUNT_POINT="/var/mnt/bitcoin-data"

case "${1:-status}" in
  unlock)
    echo "🔓 [1/4] Unlocking LUKS2 partition (${DEV_PART})..."
    if [ ! -e "/dev/mapper/${MAPPER_NAME}" ]; then
      sudo cryptsetup open "${DEV_PART}" "${MAPPER_NAME}"
    else
      echo "    -> /dev/mapper/${MAPPER_NAME} already open."
    fi

    echo "📁 [2/4] Mounting filesystem on ${MOUNT_POINT}..."
    if ! mountpoint -q "${MOUNT_POINT}"; then
      sudo mkdir -p "${MOUNT_POINT}"
      sudo mount "/dev/mapper/${MAPPER_NAME}" "${MOUNT_POINT}"
    else
      echo "    -> ${MOUNT_POINT} is already mounted."
    fi

    echo "⚙️ [3/4] Starting user Quadlets (bitcoind & electrs)..."
    systemctl --user start bitcoind electrs

    echo "✅ [4/4] Sovereign Node Online!"
    systemctl --user status bitcoind electrs --no-pager -n 2
    ;;

  lock)
    echo "⏹️ [1/3] Stopping user Quadlets (electrs & bitcoind)..."
    systemctl --user stop electrs bitcoind || true

    echo "📂 [2/3] Unmounting filesystem (${MOUNT_POINT})..."
    if mountpoint -q "${MOUNT_POINT}"; then
      sudo umount "${MOUNT_POINT}"
    else
      echo "    -> ${MOUNT_POINT} was not mounted."
    fi

    echo "🔒 [3/3] Closing LUKS2 mapping (${MAPPER_NAME})..."
    if [ -e "/dev/mapper/${MAPPER_NAME}" ]; then
      sudo cryptsetup close "${MAPPER_NAME}"
    else
      echo "    -> ${MAPPER_NAME} was not open."
    fi

    echo "🛡️ Sovereign Bitcoin vault securely encrypted and locked."
    ;;

  status)
    echo "=== Bitcoin Storage & LUKS Status ==="
    lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINTS "${DEV_PART}" || true

    echo ""
    echo "=== Systemd User Services ==="
    systemctl --user status bitcoind electrs --no-pager -n 2 || true
    ;;

  logs)
    journalctl --user -u bitcoind -u electrs -f
    ;;

  *)
    echo "Usage: $0 {unlock|lock|status|logs}"
    exit 1
    ;;
esac
