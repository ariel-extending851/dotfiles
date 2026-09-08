#!/bin/bash
set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
err() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

KEY_DIR="/root/crypt_keys"

# Formato: ["UUID_DA_PARTICAO_LUKS"]="NOME_MAPPER|PONTO_MONTAGEM|TIPO_FS"
declare -A DISKS
DISKS["679a164d-a1f7-4b28-830f-95d9cf440fd8"]="crypt_data|/mnt/data|ext4"
DISKS["edc91c14-280f-4bf8-9a01-b8fc3f569f8e"]="crypt_projects|/mnt/projects|ext4"
DISKS["f091327c-b6f2-4bfe-aef1-03ae8eaebad7"]="crypt_backup|/mnt/backup_btrfs|btrfs"

if [[ $EUID -ne 0 ]]; then
   err "Este script precisa ser rodado como root (sudo)."
fi

log "Iniciando configuração de auto-unlock (LUKS + Keyfiles)..."
mkdir -p "$KEY_DIR"
chmod 700 "$KEY_DIR"

configure_disk() {
    local uuid=$1
    local config=$2
    IFS='|' read -r mapper_name mount_point fs_type <<< "$config"

    log "---------------------------------------------------"
    log "Processando: $mapper_name ($mount_point)"

    # 1. Verificar se a partição física existe
    local physical_dev=$(blkid -U "$uuid")
    if [ -z "$physical_dev" ]; then
        warn "UUID $uuid não encontrado. O disco está conectado?"
        return
    fi

    local keyfile="$KEY_DIR/${mapper_name}.key"

    # 2. Gerar e autorizar Keyfile
    if [ ! -f "$keyfile" ]; then
        log "Gerando nova keyfile em $keyfile..."
        dd if=/dev/urandom of="$keyfile" bs=4096 count=1 status=none
        chmod 400 "$keyfile"

        warn "AUTORIZAÇÃO: Digite a senha de criptografia para $mapper_name:"
        if ! cryptsetup luksAddKey "$physical_dev" "$keyfile"; then
            rm "$keyfile"
            err "Falha ao adicionar chave ao container LUKS."
        fi
        log "Chave autorizada com sucesso."
    else
        log "Keyfile encontrada. Pulando autorização."
    fi

    # 3. Atualizar /etc/crypttab (Identificação por UUID é a mais segura)
    if ! grep -q "$mapper_name" /etc/crypttab; then
        log "Adicionando ao crypttab..."
        echo "$mapper_name UUID=$uuid $keyfile luks,discard" >> /etc/crypttab
    fi

    if [ ! -e "/dev/mapper/$mapper_name" ]; then
        log "Abrindo container LUKS..."
        cryptsetup open "$physical_dev" "$mapper_name" --key-file "$keyfile"
    fi

    # 5. Atualizar /etc/fstab e montar
    mkdir -p "$mount_point"
    if ! grep -q "$mount_point" /etc/fstab; then
        log "Adicionando ao fstab..."
        local opts="defaults,noatime,nofail"
        [[ "$fs_type" == "btrfs" ]] && opts="defaults,noatime,compress=zstd,nofail"
        echo "/dev/mapper/$mapper_name $mount_point $fs_type $opts 0 2" >> /etc/fstab
    fi

    log "Montando $mount_point..."
    mount "$mount_point" || warn "Falha ao montar. Verifique se o disco já estava montado em outro lugar."
}

for uuid in "${!DISKS[@]}"; do
    configure_disk "$uuid" "${DISKS[$uuid]}"
done

log "Recarregando daemons do systemd..."
systemctl daemon-reload

log "---------------------------------------------------"
log "Setup finalizado. Verifique /etc/crypttab e /etc/fstab."
log "Dica: Rode 'mount -a' para testar a montagem dos sistemas de arquivos."
