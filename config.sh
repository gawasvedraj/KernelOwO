#!/usr/bin/env sh
# SPDX-License-Identifier: GPL-2.0-only

# Compare kernel versions in order to apply the correct patches
version_le() {
    [ "$(printf '%s\n' "$1" "$2" | sort -V | head -n1)" = "$1" ]
}

# Avoid dirty uname
touch $KERNEL_DIR/.scmversion

msg "KernelSU"
cd $KERNEL_DIR && curl https://raw.githubusercontent.com/$KERNELSU_REPO/refs/heads/master/kernel/setup.sh | bash -s $KERNELSU_BRANCH
msg "Importing KernelSU..."

cd $KERNEL_DIR

echo "CONFIG_KSU=y" >> $DEVICE_DEFCONFIG_FILE
echo "CONFIG_KSU_EXTRAS=y" >> $DEVICE_DEFCONFIG_FILE
echo "CONFIG_KPROBES=n" >> $DEVICE_DEFCONFIG_FILE # it will conflict with KSU hooks if it's on

KSU_GIT_VERSION=$(cd KernelSU && git rev-list --count HEAD)
KERNELSU_VERSION=$(grep -r "DKSU_VERSION" $KERNEL_DIR/KernelSU/kernel/Makefile | cut -d '=' -f3)

msg "KernelSU Version: $KERNELSU_VERSION"

if [[ $VB_ENABLED == "true" ]]; then
    msg "VB"
fi
if [[ $VB_ENABLED == "false" ]]; then
    msg "NonVB"
    curl https://raw.githubusercontent.com/gawasvedraj/KernelOwO/refs/heads/master/patches/initramfs_recovery.patch | git am
fi
