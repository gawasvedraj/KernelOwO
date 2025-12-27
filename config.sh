#!/usr/bin/env sh
# SPDX-License-Identifier: GPL-2.0-only

# Compare kernel versions in order to apply the correct patches
version_le() {
    [ "$(printf '%s\n' "$1" "$2" | sort -V | head -n1)" = "$1" ]
}

# Avoid dirty uname
touch $KERNEL_DIR/.scmversion

msg "KernelSU"
if [[ $KSU_ENABLED == "true" ]]; then
    cd $KERNEL_DIR && curl https://raw.githubusercontent.com/$KERNELSU_REPO/refs/heads/main/kernel/setup.sh | bash -s $KERNELSU_BRANCH
    msg "Importing KernelSU..."

    cd $KERNEL_DIR

    echo "CONFIG_KSU=y" >> $DEVICE_DEFCONFIG_FILE
    echo "CONFIG_KSU_SUSFS=y" >> $DEVICE_DEFCONFIG_FILE
    echo "CONFIG_KSU_SUSFS_SUS_PATH=y" >> $DEVICE_DEFCONFIG_FILE
    echo "CONFIG_KSU_SUSFS_SUS_MOUNT=y" >> $DEVICE_DEFCONFIG_FILE
    echo "CONFIG_KSU_SUSFS_SUS_KSTAT=y" >> $DEVICE_DEFCONFIG_FILE
    echo "CONFIG_KSU_SUSFS_SPOOF_UNAME=y" >> $DEVICE_DEFCONFIG_FILE
    echo "CONFIG_KSU_SUSFS_ENABLE_LOG=y" >> $DEVICE_DEFCONFIG_FILE
    echo "CONFIG_KSU_SUSFS_HIDE_KSU_SUSFS_SYMBOLS=y" >> $DEVICE_DEFCONFIG_FILE
    echo "CONFIG_KSU_SUSFS_SPOOF_CMDLINE_OR_BOOTCONFIG=n" >> $DEVICE_DEFCONFIG_FILE
    echo "CONFIG_KSU_SUSFS_OPEN_REDIRECT=y" >> $DEVICE_DEFCONFIG_FILE
    echo "CONFIG_KSU_SUSFS_SUS_MAP=y" >> $DEVICE_DEFCONFIG_FILE
    echo "CONFIG_KPROBES=n" >> $DEVICE_DEFCONFIG_FILE # it will conflict with KSU hooks if it's on

    KSU_GIT_VERSION=$(cd KernelSU && git rev-list --count HEAD)
    KERNELSU_VERSION=$(grep -r "KSU_VERSION" $KERNEL_DIR/KernelSU/kernel/Makefile | cut -d '=' -f2)
    SUSFS_VERSION=$(grep "SUSFS_VERSION" $KERNEL_DIR/include/linux/susfs.h | cut -d '"' -f2 )

    msg "KernelSU Version: $KERNELSU_VERSION"
    msg "SuSFS version: $SUSFS_VERSION"
fi
if [[ $KSU_ENABLED == "false" ]]; then
    echo "KernelSU Disabled"
    cd $KERNEL_DIR
    echo "CONFIG_KSU=n" >> $DEVICE_DEFCONFIG_FILE
    echo "CONFIG_KPROBES=n" >> $DEVICE_DEFCONFIG_FILE # just in case KSU is left on by default

    KERNELSU_VERSION="Disabled"
    SUSFS_VERSION="Disabled"
fi
