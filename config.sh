#!/usr/bin/env sh

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

    cd $KERNEL_DIR

    echo "CONFIG_KSU=y" >> $DEVICE_DEFCONFIG_FILE
    echo "CONFIG_KSU_EXTRAS=y" >> $DEVICE_DEFCONFIG_FILE
    echo "CONFIG_KPROBES=n" >> $DEVICE_DEFCONFIG_FILE # it will conflict with KSU hooks if it's on

    KSU_GIT_VERSION=$(cd KernelSU && git rev-list --count HEAD)
    KERNELSU_VERSION=$(grep -r "DKSU_VERSION" $KERNEL_DIR/KernelSU/kernel/Makefile | cut -d '=' -f3)

    msg "KernelSU Version: $KERNELSU_VERSION"
fi
if [[ $KSU_ENABLED == "false" ]]; then
    echo "KernelSU Disabled"
    cd $KERNEL_DIR
    echo "CONFIG_KSU=n" >> $DEVICE_DEFCONFIG_FILE
    echo "CONFIG_KPROBES=n" >> $DEVICE_DEFCONFIG_FILE # just in case KSU is left on by default

    KERNELSU_VERSION="Disabled"
fi
