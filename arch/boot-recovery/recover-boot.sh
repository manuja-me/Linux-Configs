#!/usr/bin/env bash
# GRUB recovery for this machine (Arch on nvme1n1 + Windows on nvme0n1).
# Run from Arch Live USB as root. Uses UUIDs: NVMe device names swap between boots.
set -euo pipefail

ROOT_UUID=c75bcc13-f872-4d3c-a333-7e3574dca906   # Arch ext4 root
ESP_UUID=8865-2C71                                # Arch ESP (mounted at /boot)
WIN_ESP_UUID=4ADE-5E6B                            # Windows ESP (read-only check)
MNT=/mnt

[[ $EUID -eq 0 ]] || { echo "Run as root."; exit 1; }
[[ -d /sys/firmware/efi ]] || { echo "Not booted in UEFI mode. Reboot USB via UEFI entry."; exit 1; }

ROOT_DEV=/dev/disk/by-uuid/$ROOT_UUID
ESP_DEV=/dev/disk/by-uuid/$ESP_UUID
for d in "$ROOT_DEV" "$ESP_DEV"; do
    [[ -b $d ]] || { echo "Missing $d. Check: lsblk -f"; exit 1; }
done
[[ -b /dev/disk/by-uuid/$WIN_ESP_UUID ]] || echo "WARN: Windows ESP not found; GRUB menu will lack Windows."

cleanup() { umount -R "$MNT" 2>/dev/null || true; }
trap cleanup EXIT

mountpoint -q "$MNT" || mount "$ROOT_DEV" "$MNT"
mountpoint -q "$MNT/boot" || mount "$ESP_DEV" "$MNT/boot"

[[ -f $MNT/etc/default/grub ]] || { echo "No /etc/default/grub on root; wrong partition?"; exit 1; }

# Backup current state before touching anything
BK=$MNT/root/boot-backup-$(date +%Y%m%d-%H%M%S)
mkdir -p "$BK"
cp -a "$MNT/etc/default/grub" "$BK/"
[[ -f $MNT/boot/grub/grub.cfg ]] && cp -a "$MNT/boot/grub/grub.cfg" "$BK/"
efibootmgr -v > "$BK/efibootmgr.txt" 2>&1 || true
echo "Backup: ${BK#$MNT}"

arch-chroot "$MNT" /bin/bash -e <<'EOF'
grep -q '^GRUB_DISABLE_OS_PROBER=false' /etc/default/grub \
    || echo 'GRUB_DISABLE_OS_PROBER=false' >> /etc/default/grub

# Missing kernel → regenerate initramfs too
[[ -f /boot/vmlinuz-linux ]] || pacman -S --noconfirm linux
mkinitcpio -P

# Named entry (NVRAM) + fallback path (survives NVRAM wipes / BIOS resets)
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB --recheck
grub-install --target=x86_64-efi --efi-directory=/boot --removable --recheck

grub-mkconfig -o /boot/grub/grub.cfg
grep -q "menuentry 'Windows" /boot/grub/grub.cfg \
    && echo "OK: Windows entry present" \
    || echo "WARN: Windows entry missing (os-prober found nothing)"
EOF

# Put GRUB first in firmware boot order
GRUB_NUM=$(efibootmgr | awk '/\* GRUB$|\* GRUB\t/{print substr($1,5,4); exit}')
if [[ -n $GRUB_NUM ]]; then
    REST=$(efibootmgr | awk -F': ' '/^BootOrder/{print $2}' | tr ',' '\n' | grep -vx "$GRUB_NUM" | paste -sd,)
    efibootmgr -o "$GRUB_NUM${REST:+,$REST}" >/dev/null
fi
efibootmgr

echo "Done. Reboot, remove USB."
