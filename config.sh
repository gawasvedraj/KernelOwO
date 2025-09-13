#!/usr/bin/env sh

KERNELSU_DIR=$(find $KERNEL_DIR -mindepth 0 -maxdepth 4 \( -iname "ksu" -o -iname "kernelsu" \) -type d ! -path "*/.git/*" | cut -c3-)
KERNELSU_GITMODULE=$(grep -i "KernelSU" $KERNEL_DIR/.gitmodules)

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
    echo "CONFIG_KSU_MANUAL_HOOK=y" >> $DEVICE_DEFCONFIG_FILE
    echo "CONFIG_KPM=y" >> $DEVICE_DEFCONFIG_FILE
    echo "CONFIG_APATCH_SUPPORT=y" >> $DEVICE_DEFCONFIG_FILE
    echo "CONFIG_KSU_SUSFS=y" >> $DEVICE_DEFCONFIG_FILE
    echo "CONFIG_KSU_SUSFS_HAS_MAGIC_MOUNT=y" >> $DEVICE_DEFCONFIG_FILE
    echo "CONFIG_KSU_SUSFS_SUS_PATH=y" >> $DEVICE_DEFCONFIG_FILE
    echo "CONFIG_KSU_SUSFS_SUS_MOUNT=y" >> $DEVICE_DEFCONFIG_FILE
    echo "CONFIG_KSU_SUSFS_AUTO_ADD_SUS_KSU_DEFAULT_MOUNT=y" >> $DEVICE_DEFCONFIG_FILE
    echo "CONFIG_KSU_SUSFS_AUTO_ADD_SUS_BIND_MOUNT=y" >> $DEVICE_DEFCONFIG_FILE
    echo "CONFIG_KSU_SUSFS_TRY_UMOUNT=y" >> $DEVICE_DEFCONFIG_FILE
    echo "CONFIG_KSU_SUSFS_AUTO_ADD_TRY_UMOUNT_FOR_BIND_MOUNT=y" >> $DEVICE_DEFCONFIG_FILE
    echo "CONFIG_KSU_SUSFS_SPOOF_UNAME=y" >> $DEVICE_DEFCONFIG_FILE
    echo "CONFIG_KSU_SUSFS_ENABLE_LOG=y" >> $DEVICE_DEFCONFIG_FILE
    echo "CONFIG_KSU_SUSFS_HIDE_KSU_SUSFS_SYMBOLS=y" >> $DEVICE_DEFCONFIG_FILE
    echo "CONFIG_KSU_SUSFS_SPOOF_CMDLINE_OR_BOOTCONFIG=y" >> $DEVICE_DEFCONFIG_FILE
    echo "CONFIG_KSU_SUSFS_OPEN_REDIRECT=y" >> $DEVICE_DEFCONFIG_FILE
    echo "CONFIG_KSU_SUSFS_SUS_SU=n" >> $DEVICE_DEFCONFIG_FILE
    echo "CONFIG_KPROBES=n" >> $DEVICE_DEFCONFIG_FILE # it will conflict with KSU hooks if it's on

    SUSFS_VERSION=$(grep "SUSFS_VERSION" $KERNEL_DIR/include/linux/susfs.h | cut -d '"' -f2 )

    msg "SuSFS version: $SUSFS_VERSION"
fi
if [[ $KSU_ENABLED == "false" ]]; then
    echo "KernelSU Disabled"
    cd $KERNEL_DIR
    echo "CONFIG_KSU=n" >> $DEVICE_DEFCONFIG_FILE
    echo "CONFIG_KPROBES=n" >> $DEVICE_DEFCONFIG_FILE # just in case KSU is left on by default
    echo "CONFIG_APATCH_SUPPORT=y" >> $DEVICE_DEFCONFIG_FILE

    SUSFS_VERSION="Disabled"
fi
