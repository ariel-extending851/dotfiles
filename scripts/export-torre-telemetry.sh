#!/usr/bin/env bash
# export-torre-telemetry.sh - Generates Prometheus metrics for Torre Fedora
# Collects: NVIDIA GPU (RTX 3070), Bitcoin Core node, physical disks, and LUKS state.

set -euo pipefail

METRICS_DIR="${HOME}/.local/share/node_exporter/textfile"
mkdir -p "${METRICS_DIR}"
TMP_FILE="${METRICS_DIR}/torre.prom.tmp"
TARGET_FILE="${METRICS_DIR}/torre.prom"

cat << 'EOF' > "${TMP_FILE}"
# HELP node_gpu_temperature_celsius Temperature of NVIDIA GPU
# TYPE node_gpu_temperature_celsius gauge
# HELP node_gpu_utilization_percent GPU core utilization percentage
# TYPE node_gpu_utilization_percent gauge
# HELP node_gpu_memory_utilization_percent GPU memory utilization percentage
# TYPE node_gpu_memory_utilization_percent gauge
# HELP node_gpu_memory_total_bytes Total GPU VRAM in bytes
# TYPE node_gpu_memory_total_bytes gauge
# HELP node_gpu_memory_used_bytes Used GPU VRAM in bytes
# TYPE node_gpu_memory_used_bytes gauge
EOF

# 1. NVIDIA GPU Metrics
if command -v nvidia-smi >/dev/null 2>&1; then
    GPU_DATA=$(nvidia-smi --query-gpu=temperature.gpu,utilization.gpu,utilization.memory,memory.total,memory.used --format=csv,noheader,nounits 2>/dev/null || true)
    if [ -n "$GPU_DATA" ]; then
        IFS=',' read -r TEMP UTIL_GPU UTIL_MEM MEM_TOTAL MEM_USED <<< "$GPU_DATA"
        TEMP=$(echo "$TEMP" | tr -d ' ')
        UTIL_GPU=$(echo "$UTIL_GPU" | tr -d ' ')
        UTIL_MEM=$(echo "$UTIL_MEM" | tr -d ' ')
        MEM_TOTAL=$(echo "$MEM_TOTAL" | tr -d ' ')
        MEM_USED=$(echo "$MEM_USED" | tr -d ' ')

        MEM_TOTAL_BYTES=$((MEM_TOTAL * 1024 * 1024))
        MEM_USED_BYTES=$((MEM_USED * 1024 * 1024))

        cat << EOF >> "${TMP_FILE}"
node_gpu_temperature_celsius{gpu="0",model="RTX_3070"} ${TEMP}
node_gpu_utilization_percent{gpu="0",model="RTX_3070"} ${UTIL_GPU}
node_gpu_memory_utilization_percent{gpu="0",model="RTX_3070"} ${UTIL_MEM}
node_gpu_memory_total_bytes{gpu="0",model="RTX_3070"} ${MEM_TOTAL_BYTES}
node_gpu_memory_used_bytes{gpu="0",model="RTX_3070"} ${MEM_USED_BYTES}
EOF
    fi
fi

# 2. Bitcoin Core Full Node Metrics
cat << 'EOF' >> "${TMP_FILE}"
# HELP node_bitcoin_up Status of Bitcoin Core container (1=running, 0=stopped)
# TYPE node_bitcoin_up gauge
# HELP node_bitcoin_blocks Current verified block height
# TYPE node_bitcoin_blocks gauge
# HELP node_bitcoin_headers Best header height
# TYPE node_bitcoin_headers gauge
# HELP node_bitcoin_verification_progress Verification progress ratio (0.0 to 1.0)
# TYPE node_bitcoin_verification_progress gauge
# HELP node_bitcoin_size_on_disk_bytes Blockchain size stored on disk
# TYPE node_bitcoin_size_on_disk_bytes gauge
# HELP node_bitcoin_peers Connected P2P network peers
# TYPE node_bitcoin_peers gauge
EOF

if podman container exists bitcoind 2>/dev/null && [ "$(podman inspect -f '{{.State.Status}}' bitcoind 2>/dev/null)" = "running" ]; then
    BTC_INFO=$(podman exec bitcoind bitcoin-cli -datadir=/home/bitcoin/.bitcoin getblockchaininfo 2>/dev/null || true)
    BTC_NET=$(podman exec bitcoind bitcoin-cli -datadir=/home/bitcoin/.bitcoin getnetworkinfo 2>/dev/null || true)
    
    if [ -n "$BTC_INFO" ] && [ -n "$BTC_NET" ]; then
        BLOCKS=$(echo "$BTC_INFO" | jq -r '.blocks // 0')
        HEADERS=$(echo "$BTC_INFO" | jq -r '.headers // 0')
        PROGRESS=$(echo "$BTC_INFO" | jq -r '.verificationprogress // 0')
        SIZE=$(echo "$BTC_INFO" | jq -r '.size_on_disk // 0')
        PEERS=$(echo "$BTC_NET" | jq -r '.connections // 0')

        cat << EOF >> "${TMP_FILE}"
node_bitcoin_up 1
node_bitcoin_blocks ${BLOCKS}
node_bitcoin_headers ${HEADERS}
node_bitcoin_verification_progress ${PROGRESS}
node_bitcoin_size_on_disk_bytes ${SIZE}
node_bitcoin_peers ${PEERS}
EOF
    else
        echo "node_bitcoin_up 0" >> "${TMP_FILE}"
    fi
else
    echo "node_bitcoin_up 0" >> "${TMP_FILE}"
fi

# 3. Disks & LUKS Cold Storage Status
cat << 'EOF' >> "${TMP_FILE}"
# HELP node_disk_luks_unlocked State of LUKS partition (1=unlocked, 0=locked)
# TYPE node_disk_luks_unlocked gauge
# HELP node_disk_physical_size_bytes Physical block device capacity in bytes
# TYPE node_disk_physical_size_bytes gauge
EOF

if [ -e "/dev/mapper/bitcoin-crypt" ]; then
    echo 'node_disk_luks_unlocked{device="sdc1",mapper="bitcoin-crypt"} 1' >> "${TMP_FILE}"
else
    echo 'node_disk_luks_unlocked{device="sdc1",mapper="bitcoin-crypt"} 0' >> "${TMP_FILE}"
fi

# Query physical disk sizes from lsblk
lsblk -b -d -n -o NAME,SIZE,MODEL 2>/dev/null | while read -r DEV SIZE MODEL; do
    MODEL_CLEAN=$(echo "$MODEL" | tr ' ' '_' | tr -cd '[:alnum:]_')
    if [ -n "$SIZE" ] && [ "$SIZE" -gt 0 ] 2>/dev/null; then
        echo "node_disk_physical_size_bytes{device=\"${DEV}\",model=\"${MODEL_CLEAN}\"} ${SIZE}" >> "${TMP_FILE}"
    fi
done

# Atomically replace target file
mv "${TMP_FILE}" "${TARGET_FILE}"
chmod 0644 "${TARGET_FILE}"
