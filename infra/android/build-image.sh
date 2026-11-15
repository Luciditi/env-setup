#!/usr/bin/env bash
set -euo pipefail

############################################################################
# ANDROID AVF DEBIAN IMAGE BUILDER
############################################################################
# Downloads Google's upstream AVF Debian aarch64 archive (images.tar.gz),
# expands and mounts root_part, provisions env-setup under the default
# 'droid' user (plus 'admin' SSH & virtio-net DHCP for Tart VM), shrinks
# the ext4 partition, and outputs a sparse images.tar.gz (and optional
# stitched GPT disk.img for Tart VM).

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
# shellcheck source=scripts/_common
source "$REPO_DIR/scripts/_common"

DEFAULT_SOURCE_URL="https://dl.google.com/android/ferrochrome/latest/aarch64/images.tar.gz"
CONFIG_PRESET="default"
OUTPUT_PATH="images.tar.gz"
BASE_CACHE=""
BASE_ONLY="0"
TART_DISK=""
SOURCE_URL="$DEFAULT_SOURCE_URL"
DRY_RUN="0"
GROW_SIZE_GB="${ANDROID_IMAGE_GROW_GB:-12}"

usage() {
    cat << EOF
Usage: $(basename "$0") [options]

Build a custom Android Linux Terminal (AVF) Debian aarch64 image archive
(images.tar.gz) and optional Tart VM GPT disk image (disk.img).

Options:
  -c, --config <preset>     Config preset: none, mini, default, most (default: default)
  -o, --output <path>       Output archive path (default: images.tar.gz)
  -b, --base-cache <path>   Read/write path for warmed base root_part image
      --base-only           Build and save only the warmed base root_part image
  -t, --tart-disk <path>    Also stitch efi_part + root_part into a GPT raw disk.img for Tart
  -u, --source-url <url>    Upstream AVF archive URL
  -n, --dry-run             Validate options and print execution plan without building
  -h, --help                Display this help message
EOF
}

resolve_config_file() {
    local preset="$1"
    case "$preset" in
        none)    printf '%s\n' ".none.config.yml" ;;
        mini)    printf '%s\n' ".mini.config.yml" ;;
        default) printf '%s\n' "default.config.yml" ;;
        most)    printf '%s\n' ".most.config.yml" ;;
        *)       return 1 ;;
    esac
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -c|--config)
            CONFIG_PRESET="${2:-}"
            shift 2
            ;;
        -o|--output)
            OUTPUT_PATH="${2:-}"
            shift 2
            ;;
        -b|--base-cache)
            BASE_CACHE="${2:-}"
            shift 2
            ;;
        --base-only)
            BASE_ONLY="1"
            shift
            ;;
        -t|--tart-disk)
            TART_DISK="${2:-}"
            shift 2
            ;;
        -u|--source-url)
            SOURCE_URL="${2:-}"
            shift 2
            ;;
        -n|--dry-run)
            DRY_RUN="1"
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo -e "${C_ERR}Unknown option: $1${C_RES}" >&2
            usage >&2
            exit 1
            ;;
    esac
done

if ! CONFIG_FILE="$(resolve_config_file "$CONFIG_PRESET")"; then
    echo -e "${C_ERR}Unknown config '${CONFIG_PRESET}' (expected: none, mini, default, most)${C_RES}" >&2
    exit 1
fi

echo -e "${C_HIL}Android AVF Debian Image Build Plan:${C_RES}"
echo "  Config preset: ${CONFIG_PRESET} (${CONFIG_FILE})"
echo "  Source URL:    ${SOURCE_URL}"
echo "  Output archive: ${OUTPUT_PATH}"
if [[ -n "$BASE_CACHE" ]]; then
    echo "  Base cache:    ${BASE_CACHE} (base-only=${BASE_ONLY})"
fi
if [[ -n "$TART_DISK" ]]; then
    echo "  Tart disk image: ${TART_DISK}"
fi

if [[ "$DRY_RUN" == "1" ]]; then
    exit 0
fi

if [[ "$(uname -s)" != "Linux" ]]; then
    echo -e "${C_ERR}build-image.sh requires an aarch64 Linux host (or run 'env-setup vm android build' on macOS).${C_RES}" >&2
    exit 1
fi

if [[ "$(id -u)" -ne 0 ]]; then
    echo -e "${C_ERR}build-image.sh must run as root (use sudo) to loop-mount and chroot into root_part.${C_RES}" >&2
    exit 1
fi

WORK_DIR="$(mktemp -d -t envsetup-android-XXXXXX)"
MOUNT_DIR="$WORK_DIR/mnt"
mkdir -p "$MOUNT_DIR"

cleanup_mounts() {
    set +e
    if mountpoint -q "$MOUNT_DIR/dev/shm" 2>/dev/null; then umount -lf "$MOUNT_DIR/dev/shm"; fi
    if mountpoint -q "$MOUNT_DIR/dev/pts" 2>/dev/null; then umount -lf "$MOUNT_DIR/dev/pts"; fi
    if mountpoint -q "$MOUNT_DIR/dev" 2>/dev/null; then umount -lf "$MOUNT_DIR/dev"; fi
    if mountpoint -q "$MOUNT_DIR/sys" 2>/dev/null; then umount -lf "$MOUNT_DIR/sys"; fi
    if mountpoint -q "$MOUNT_DIR/proc" 2>/dev/null; then umount -lf "$MOUNT_DIR/proc"; fi
    if mountpoint -q "$MOUNT_DIR" 2>/dev/null; then umount -lf "$MOUNT_DIR"; fi
    rm -rf "$WORK_DIR"
}
trap cleanup_mounts EXIT

echo -e "\n${C_HIL}1. Fetching upstream AVF Debian archive...${C_RES}"
curl -fL --retry 3 -o "$WORK_DIR/upstream-images.tar.gz" "$SOURCE_URL"
tar -xzf "$WORK_DIR/upstream-images.tar.gz" -C "$WORK_DIR"
rm -f "$WORK_DIR/upstream-images.tar.gz"

mount_chroot() {
    mount -o loop "$WORK_DIR/root_part" "$MOUNT_DIR"
    mount -t proc /proc "$MOUNT_DIR/proc"
    mount -t sysfs /sys "$MOUNT_DIR/sys"
    mount --bind /dev "$MOUNT_DIR/dev"
    mount --bind /dev/pts "$MOUNT_DIR/dev/pts"
    mkdir -p "$MOUNT_DIR/dev/shm" "$MOUNT_DIR/run/shm"
    mount -t tmpfs -o mode=1777 tmpfs "$MOUNT_DIR/dev/shm"
    chmod 1777 "$MOUNT_DIR/dev/shm" "$MOUNT_DIR/run/shm"
    if [[ -L "$MOUNT_DIR/etc/resolv.conf" || -f "$MOUNT_DIR/etc/resolv.conf" ]]; then
        mv -f "$MOUNT_DIR/etc/resolv.conf" "$MOUNT_DIR/etc/resolv.conf.bak"
    fi
    cp -f /etc/resolv.conf "$MOUNT_DIR/etc/resolv.conf"
}

unmount_chroot() {
    if [[ -e "$MOUNT_DIR/etc/resolv.conf.bak" || -L "$MOUNT_DIR/etc/resolv.conf.bak" ]]; then
        mv -f "$MOUNT_DIR/etc/resolv.conf.bak" "$MOUNT_DIR/etc/resolv.conf"
    fi
    sync
    umount "$MOUNT_DIR/dev/shm"
    umount "$MOUNT_DIR/dev/pts"
    umount "$MOUNT_DIR/dev"
    umount "$MOUNT_DIR/sys"
    umount "$MOUNT_DIR/proc"
    umount "$MOUNT_DIR"
}

if [[ -n "$BASE_CACHE" && -f "$BASE_CACHE" && "$BASE_ONLY" == "0" ]]; then
    echo -e "\n${C_HIL}2. Restoring warmed base root_part from ${BASE_CACHE}...${C_RES}"
    cp -f "$BASE_CACHE" "$WORK_DIR/root_part"
else
    echo -e "\n${C_HIL}2. Expanding root_part (+${GROW_SIZE_GB}G) and warming base packages...${C_RES}"
    truncate -s "+${GROW_SIZE_GB}G" "$WORK_DIR/root_part"
    e2fsck -f -y "$WORK_DIR/root_part" || true
    resize2fs "$WORK_DIR/root_part"

    WARM_FORMULAE="gcc docker $("$REPO_DIR/scripts/formula-intersection" --format=space)"
    mount_chroot

    chroot "$MOUNT_DIR" /bin/bash -c "
        set -euo pipefail
        export DEBIAN_FRONTEND=noninteractive TZ=Etc/UTC
        apt-get update -y
        apt-get install -y --no-install-recommends \
            ansible \
            build-essential \
            ca-certificates \
            curl \
            file \
            git \
            libnotify-bin \
            locales \
            openssh-server \
            openssl \
            procps \
            python3 \
            python3-apt \
            sudo \
            vim \
            zsh

        # Ensure default Android Terminal user 'droid' (UID 1000) and Tart SSH user 'admin' exist
        if ! id -u droid >/dev/null 2>&1; then
            useradd -m -d /home/droid -s /bin/bash -G sudo -u 1000 droid || useradd -m -d /home/droid -s /bin/bash -G sudo droid
        fi
        if ! id -u admin >/dev/null 2>&1; then
            useradd -p \"\$(openssl passwd -1 admin)\" -m -d /home/admin -s /bin/bash -G sudo admin
        fi
        echo '%sudo ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/env-setup
        chmod 0440 /etc/sudoers.d/env-setup

        # Enable SSH and fallback DHCP on virtio-net interfaces for Tart VM local testing
        systemctl enable ssh || true
        mkdir -p /etc/systemd/network
        cat > /etc/systemd/network/99-tart-dhcp.network << 'NETEOF'
[Match]
Name=en* eth*

[Network]
DHCP=yes
NETEOF

        mkdir -p /home/droid/.ssh /home/linuxbrew
        ssh-keyscan github.com >> /home/droid/.ssh/known_hosts 2>/dev/null || true
        chown -R droid:droid /home/droid/.ssh /home/linuxbrew
        chmod 700 /home/droid/.ssh

        su - droid -c '
            set -euo pipefail
            export NONINTERACTIVE=1
            export HOMEBREW_NO_AUTO_UPDATE=1 HOMEBREW_NO_INSTALL_CLEANUP=1 HOMEBREW_NO_ANALYTICS=1
            if [[ ! -x /home/linuxbrew/.linuxbrew/bin/brew ]]; then
                /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\"
                for rc in .bash_profile .bashrc .zshrc; do
                    echo \"eval \\\"\\\$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)\\\"\" >> \"/home/droid/\$rc\"
                done
            fi
            eval \"\$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)\"
            ansible-galaxy role install geerlingguy.dotfiles
            ansible-galaxy collection install community.general
            brew install ${WARM_FORMULAE} || true
        '
        apt-get clean
    "

    unmount_chroot

    if [[ -n "$BASE_CACHE" ]]; then
        echo -e "\n${C_HIL}Saving warmed base root_part to ${BASE_CACHE}...${C_RES}"
        mkdir -p "$(dirname "$BASE_CACHE")"
        cp -f --sparse=always "$WORK_DIR/root_part" "$BASE_CACHE"
    fi

    if [[ "$BASE_ONLY" == "1" ]]; then
        echo -e "${C_SUC}Base root_part cached at ${BASE_CACHE}.${C_RES}"
        exit 0
    fi
fi

echo -e "\n${C_HIL}3. Provisioning env-setup (${CONFIG_PRESET}) inside root_part...${C_RES}"
mount_chroot

rm -rf "$MOUNT_DIR/home/droid/env-setup"
cp -rf "$REPO_DIR" "$MOUNT_DIR/home/droid/env-setup"
cp -f "$REPO_DIR/$CONFIG_FILE" "$MOUNT_DIR/home/droid/env-setup/config.yml"

if [[ -n "${ENVSETUP_SSH_KEY_FILE:-}" && -s "$ENVSETUP_SSH_KEY_FILE" ]]; then
    cp -f "$ENVSETUP_SSH_KEY_FILE" "$MOUNT_DIR/home/droid/.ssh/id_rsa"
    chmod 400 "$MOUNT_DIR/home/droid/.ssh/id_rsa"
fi

chroot "$MOUNT_DIR" /bin/bash -c "
    set -euo pipefail
    chown -R droid:droid /home/droid/env-setup /home/droid/.ssh
    su - droid -c '
        set -euo pipefail
        export PATH=\"/home/linuxbrew/.linuxbrew/bin:/home/linuxbrew/.linuxbrew/sbin:\$PATH\"
        export HOMEBREW_NO_AUTO_UPDATE=1 HOMEBREW_NO_INSTALL_CLEANUP=1 HOMEBREW_NO_ANALYTICS=1
        export ENVSETUP_INTERACT=0 ANSIBLE_SUDO=-n
        for rc in .bashrc .zshrc .profile .zprofile; do
            echo \"alias env-setup=\\\"/home/droid/env-setup/scripts/env-setup\\\"\" >> \"/home/droid/\$rc\"
        done
        if [[ ! -s /home/droid/.ssh/id_rsa ]]; then
            git config --global url.\"https://github.com/\".insteadOf \"git@github.com:\"
        fi
        if [[ ! -d /home/droid/env-setup-dotfiles ]]; then
            git clone https://github.com/Luciditi/env-setup-dotfiles.git /home/droid/env-setup-dotfiles || true
        fi
        if [[ ! -d /home/droid/env-setup-prv-dotfiles ]]; then
            git clone https://github.com/Luciditi/env-setup-dotfiles.git /home/droid/env-setup-prv-dotfiles || true
        fi
        /home/droid/env-setup/scripts/env-setup 01-config
        /home/droid/env-setup/scripts/env-setup 02-cli
        /home/droid/env-setup/scripts/env-setup 04-packages
        /home/droid/env-setup/scripts/env-setup 05-repos
        /home/droid/env-setup/scripts/env-setup 07-cloud
        /home/droid/env-setup/scripts/env-setup 08-prefs
        git config --global --unset-all url.\"https://github.com/\".insteadOf || true
    '
    rm -f /home/droid/.ssh/id_rsa
    apt-get clean
    rm -rf /var/lib/apt/lists/*
"

unmount_chroot

echo -e "\n${C_HIL}4. Shrinking ext4 root_part and packaging sparse images.tar.gz...${C_RES}"
e2fsck -f -y "$WORK_DIR/root_part" || true
resize2fs -M "$WORK_DIR/root_part"

# Add 512MB free headroom so the booted VM has immediate writable space before ballooning
BLOCK_COUNT=$(dumpe2fs -h "$WORK_DIR/root_part" 2>/dev/null | awk -F: '/Block count:/ {gsub(/ /, "", $2); print $2}')
BLOCK_SIZE=$(dumpe2fs -h "$WORK_DIR/root_part" 2>/dev/null | awk -F: '/Block size:/ {gsub(/ /, "", $2); print $2}')
FINAL_BYTES=$(( BLOCK_COUNT * BLOCK_SIZE + 536870912 ))
truncate -s "$FINAL_BYTES" "$WORK_DIR/root_part"
resize2fs "$WORK_DIR/root_part"

mkdir -p "$(dirname "$(abspath "$OUTPUT_PATH")")"
tar -C "$WORK_DIR" -czSf "$(abspath "$OUTPUT_PATH")" build_id efi_part root_part vm_config.json
echo -e "${C_SUC}Created Android AVF archive: ${OUTPUT_PATH}${C_RES}"

if [[ -n "$TART_DISK" ]]; then
    echo -e "\n${C_HIL}5. Stitching GPT disk image for Tart VM (${TART_DISK})...${C_RES}"
    EFI_SIZE=$(stat -c '%s' "$WORK_DIR/efi_part")
    ROOT_SIZE=$(stat -c '%s' "$WORK_DIR/root_part")
    # 2MB alignment padding at start and end for GPT headers
    TOTAL_DISK_BYTES=$(( EFI_SIZE + ROOT_SIZE + 4194304 ))
    EFI_SECTORS=$(( EFI_SIZE / 512 ))
    ROOT_START_SECTOR=$(( 2048 + EFI_SECTORS ))

    mkdir -p "$(dirname "$(abspath "$TART_DISK")")"
    truncate -s "$TOTAL_DISK_BYTES" "$TART_DISK"
    sfdisk "$TART_DISK" << SFDISK_EOF
label: gpt
unit: sectors

1 : start=2048, size=${EFI_SECTORS}, type=C12A7328-F81F-11D2-BA4B-00A0C93EC93B, name="EFI"
2 : start=${ROOT_START_SECTOR}, type=B921B045-1DF0-41C3-AF44-4C6F280D3FAE, name="ROOT"
SFDISK_EOF

    dd if="$WORK_DIR/efi_part" of="$TART_DISK" bs=512 seek=2048 conv=notrunc,sparse status=none
    dd if="$WORK_DIR/root_part" of="$TART_DISK" bs=512 seek="$ROOT_START_SECTOR" conv=notrunc,sparse status=none
    echo -e "${C_SUC}Created Tart GPT disk image: ${TART_DISK}${C_RES}"
fi
