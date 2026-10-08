#!/usr/bin/bash
# Called by the Containerfile, see the description there.
#
# Inputs:
#   IMAGE_REF            Image to install, has to be available in the containers-storage of the live environment
#   UPDATE_IMAGE_REF     Image the installed system gets its updates from, defaults to IMAGE_REF
#   ISO_NAME, ISO_LABEL  Boot menu name and volume label
#   /ctx/hook.sh         Optional, script to customize the live environment or the installer

set -xeuo pipefail

: "${IMAGE_REF:?}"
UPDATE_IMAGE_REF="${UPDATE_IMAGE_REF:-${IMAGE_REF}}"
ISO_NAME="${ISO_NAME:-$(. /etc/os-release && echo "$NAME $VERSION_ID")}"
if [[ -z "${ISO_LABEL:-}" ]]; then
    # Volume labels are limited to 32 characters
    ISO_LABEL="$(echo -n "${ISO_NAME}" | tr -c 'A-Za-z0-9_-' '-' | cut -c1-27)-Live"
fi

case "$(uname -m)" in
    x86_64) EFI_ARCH=x64 ;;
    aarch64) EFI_ARCH=aa64 ;;
    *) echo "Unsupported architecture $(uname -m)"; exit 1 ;;
esac

# /root is a symlink into /var, which is empty in the image
mkdir -p "$(realpath /root)"

dnf install -y \
    anaconda-live \
    dracut-live \
    livesys-scripts \
    "grub2-efi-${EFI_ARCH}-cdboot" \
    fuse-overlayfs \
    isomd5sum \
    squashfs-tools \
    xorriso
dnf clean all

### Boot

# The initramfs has to be able to find and mount the squashfs in the ISO
KERNEL="$(basename /usr/lib/modules/*)"
DRACUT_NO_XATTR=1 dracut --force --zstd --reproducible --no-hostonly \
    --add "dmsquash-live dmsquash-live-autooverlay" \
    "/usr/lib/modules/${KERNEL}/initramfs.img" "${KERNEL}"

# image-builder takes shim and grub from /boot/efi, bootc images keep them in the bootupd directory
mkdir -p /boot/efi/EFI
cp -av /usr/lib/bootupd/updates/EFI/. /boot/efi/EFI/

mkdir -p /usr/lib/image-builder/bootc
cat > /usr/lib/image-builder/bootc/iso.yaml <<EOYAML
label: "${ISO_LABEL}"
grub2:
  timeout: 10
  entries:
    - name: "Start ${ISO_NAME} Live"
      linux: "/images/pxeboot/vmlinuz root=live:CDLABEL=${ISO_LABEL} rd.live.image enforcing=0 quiet rhgb"
      initrd: "/images/pxeboot/initrd.img"
    - name: "Start ${ISO_NAME} Live (basic graphics mode)"
      linux: "/images/pxeboot/vmlinuz root=live:CDLABEL=${ISO_LABEL} rd.live.image enforcing=0 quiet rhgb nomodeset"
      initrd: "/images/pxeboot/initrd.img"
EOYAML

### Live session

# Has to match one of /usr/libexec/livesys/sessions.d/livesys-*
SESSION_FILE="$(find /usr/share/wayland-sessions /usr/share/xsessions -maxdepth 1 -name '*.desktop' -printf '%f\n' 2>/dev/null | sort | head -1)"
case "${SESSION_FILE}" in
    budgie*) LIVESYS_SESSION=budgie ;;
    cosmic*) LIVESYS_SESSION=cosmic ;;
    gnome*) LIVESYS_SESSION=gnome ;;
    plasma*) LIVESYS_SESSION=kde ;;
    sway*) LIVESYS_SESSION=sway ;;
    xfce*) LIVESYS_SESSION=xfce ;;
    *) LIVESYS_SESSION="" ;;
esac
sed -i "s/^livesys_session=.*/livesys_session=\"${LIVESYS_SESSION}\"/" /etc/sysconfig/livesys

# Partitioning tools, to prepare the disks before installing. GParted isn't packaged for EL10, use
# the desktop's own tool instead. KDE Partition Manager comes from EPEL, which the image might not
# have enabled.
dnf install -y parted
if [[ "${LIVESYS_SESSION}" != kde ]] || ! dnf install -y kde-partitionmanager; then
    dnf install -y gnome-disk-utility
fi
dnf clean all
systemctl enable livesys.service livesys-late.service

# The system is not booted from a bootc deployment, so it can't be updated
systemctl disable bootc-fetch-apply-updates.timer rpm-ostreed-automatic.timer || :

# / in the live environment is an overlay backed by /run, which is too small for the temporary
# files ostree needs during the installation
cat > /usr/lib/systemd/system/var-tmp.mount <<'EOUNIT'
[Unit]
Description=Larger tmpfs for /var/tmp on the live system

[Mount]
What=tmpfs
Where=/var/tmp
Type=tmpfs
Options=size=50%%,nr_inodes=1m

[Install]
WantedBy=local-fs.target
EOUNIT
systemctl enable var-tmp.mount

### Installer

# The image is embedded in the ISO by image-builder (--bootc-installer-payload-ref), and installed
# with `bootc install`. The installed system gets its updates from UPDATE_IMAGE_REF, and verifies
# them according to the policy in /etc/containers/policy.json of the image.
cat >> /usr/share/anaconda/interactive-defaults.ks <<EOKS

bootc --source-imgref containers-storage:${IMAGE_REF} --target-imgref ${UPDATE_IMAGE_REF}
EOKS

### Customizations

if [[ -f /ctx/hook.sh ]]; then
    bash /ctx/hook.sh
fi

cat /usr/share/anaconda/interactive-defaults.ks
