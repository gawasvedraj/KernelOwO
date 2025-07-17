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
    cd $KERNEL_DIR && curl https://raw.githubusercontent.com/$KERNELSU_REPO/refs/heads/master/kernel/setup.sh | bash -s $KERNELSU_BRANCH
    msg "Importing KernelSU..."

    git clone https://gitlab.com/simonpunk/susfs4ksu -b kernel-5.4 susfs4ksu
    cp susfs4ksu/kernel_patches/fs/* fs/
    cp susfs4ksu/kernel_patches/include/linux/* include/linux/
    patch -p1 -F 3 < susfs4ksu/kernel_patches/50_add_susfs_in_kernel-5.4.patch
    msg "Importing SuSFS into 5.4 kernel..."

    echo "CONFIG_KSU=y" >> $DEVICE_DEFCONFIG_FILE
    echo "CONFIG_KSU_SUSFS=y" >> $DEVICE_DEFCONFIG_FILE
    echo "CONFIG_KPROBES=n" >> $DEVICE_DEFCONFIG_FILE # it will conflict with KSU hooks if it's on

    KSU_GIT_VERSION=$(cd KernelSU && git rev-list --count HEAD)
    KERNELSU_VERSION=$(($KSU_GIT_VERSION + 10200))
    SUSFS_VERSION=$(grep "SUSFS_VERSION" $KERNEL_DIR/include/linux/susfs.h | cut -d '"' -f2 )

    msg "KernelSU Version: $KERNELSU_VERSION"
    msg "SuSFS version: $SUSFS_VERSION"
    sed -i "s/^CONFIG_LOCALVERSION=.*/CONFIG_LOCALVERSION=\"-qgki-κsu\"/" $DEVICE_DEFCONFIG_FILE
fi
if [[ $KSU_ENABLED == "false" ]]; then
    echo "KernelSU Disabled"
    cd $KERNEL_DIR
    echo "CONFIG_KSU=n" >> $DEVICE_DEFCONFIG_FILE
    echo "CONFIG_KPROBES=n" >> $DEVICE_DEFCONFIG_FILE # just in case KSU is left on by default
    echo "CONFIG_APATCH_SUPPORT=y" >> $DEVICE_DEFCONFIG_FILE

    KERNELSU_VERSION="Disabled"
    SUSFS_VERSION="Disabled"
fi
