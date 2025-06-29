#!/usr/bin/env sh

# Changable Data
# ------------------------------------------------------------

# Kernel
KERNEL_NAME="QGKI"
KERNEL_GIT="https://github.com/gawasvedraj/android_kernel_xiaomi_stone.git"
KERNEL_BRANCH="16"

# KernelSU
KERNELSU_REPO="backslashxx/KernelSU"
KERNELSU_BRANCH="12072+sus155"
KSU_ENABLED="false"

# Anykernel3
ANYKERNEL3_GIT="https://github.com/gawasvedraj/AnyKernel3.git"
ANYKERNEL3_BRANCH="stone"

# Build
DEVICE_CODE="stone"
DEVICE_DEFCONFIG="stone_defconfig"
COMMON_DEFCONFIG=""
DEVICE_ARCH="arch/arm64"

# Clang
CLANG_REPO="crdroidandroid/android_prebuilts_clang_host_linux-x86_clang-r547379"
CLANG_BRANCH="15.0"

# ------------------------------------------------------------

# Input Variables
if [[ $1 == "KSU" ]]; then
    KSU_ENABLED="true"
    echo "Input changed KSU_ENABLED to true"
elif [[ $1 == "NonKSU" ]]; then
    KSU_ENABLED="false"
    echo "Input changed KSU_ENABLED to false"
fi

if [[ $2 == *.git ]]; then
    KERNEL_GIT=$2
    echo "Input changed KERNEL_GIT to $KERNEL_GIT"
fi

# Set variables
WORKDIR="$(pwd)"

CLANG_DIR="$WORKDIR/Clang/bin"

KERNEL_REPO="${KERNEL_GIT::-4}/"
KERNEL_SOURCE="${KERNEL_REPO::-1}/tree/$KERNEL_BRANCH"
KERNEL_DIR="$WORKDIR/$KERNEL_NAME"

KERNELSU_SOURCE="https://github.com/$KERNELSU_REPO"
CLANG_SOURCE="https://gitlab.com/$CLANG_REPO"
README="https://github.com/gawasvedraj/KernelOwO/blob/master/README.md"

DEVICE_DEFCONFIG_FILE="$KERNEL_DIR/$DEVICE_ARCH/configs/$DEVICE_DEFCONFIG"
IMAGE="$KERNEL_DIR/out/$DEVICE_ARCH/boot/Image"
DTB="$KERNEL_DIR/out/$DEVICE_ARCH/boot/dtb"
DTBO="$KERNEL_DIR/out/$DEVICE_ARCH/boot/dtbo"

export KBUILD_BUILD_USER=Vedraj
export KBUILD_BUILD_HOST=GitHubCI

# Highlight
msg() {
	echo
	echo -e "\e[1;33m$*\e[0m"
	echo
}

cd $WORKDIR

# Setup
msg "Setup"

msg "Clang"
git config --global http.postBuffer 524288000
git clone --depth=1 $CLANG_SOURCE --single-branch -b $CLANG_BRANCH Clang

CLANG_VERSION="$($CLANG_DIR/clang --version | head -n 1 | cut -f1 -d "(" | sed 's/.$//')"
# CLANG_VERSION=${CLANG_VERSION::-3}
LLD_VERSION="$($CLANG_DIR/ld.lld --version | head -n 1 | cut -f1 -d "(" | sed 's/.$//')"

msg "Kernel"
git clone --depth=1 $KERNEL_GIT --single-branch -b $KERNEL_BRANCH $KERNEL_DIR

KERNEL_VERSION=$(cat $KERNEL_DIR/Makefile | grep -w "VERSION =" | cut -d '=' -f 2 | cut -b 2-)\
.$(cat $KERNEL_DIR/Makefile | grep -w "PATCHLEVEL =" | cut -d '=' -f 2 | cut -b 2-)\
.$(cat $KERNEL_DIR/Makefile | grep -w "SUBLEVEL =" | cut -d '=' -f 2 | cut -b 2-)
# .$(cat $KERNEL_DIR/Makefile | grep -w "EXTRAVERSION =" | cut -d '=' -f 2 | cut -b 2-)

KERNEL_VER=$(echo $KERNEL_VERSION | cut -d. -f1,2)

msg "Kernel Version: $KERNEL_VERSION"

TITLE=$KERNEL_NAME-$KERNEL_VERSION

source ./config.sh

# Build
msg "Build"

args="PATH=$CLANG_DIR:$PATH \
ARCH=arm64 \
SUBARCH=arm64 \
CROSS_COMPILE=aarch64-linux-gnu- \
CROSS_COMPILE_ARM32=arm-linux-gnueabi- \
CROSS_COMPILE_COMPAT=arm-linux-gnueabi- \
CC=clang \
LD=ld.lld \
LLVM=1 \
LLVM_IAS=1"

rm -rf out
make O=out $args $DEVICE_DEFCONFIG
if [[ ! -z "$COMMON_DEFCONFIG" ]]; then
  make O=out $args $COMMON_DEFCONFIG
fi
make O=out $args kernelversion
make O=out $args -j"$(nproc --all)"
msg "Kernel version: $KERNEL_VERSION"

# Package
msg "Package"
cd $WORKDIR
git clone --depth=1 $ANYKERNEL3_GIT -b $ANYKERNEL3_BRANCH $WORKDIR/Anykernel3
cd $WORKDIR/Anykernel3
AK3_DEVICE=$(grep -m 1 "device.name.*=$DEVICE_CODE" anykernel.sh | cut -d '=' -f 2)
DEVICE_DEFCONFIG_CODE=$(basename $DEVICE_DEFCONFIG | cut -d '_' -f 1 | cut -d '-' -f 1)
COMMON_DEFCONFIG_CODE=$(basename $COMMON_DEFCONFIG | cut -d '.' -f 1 | cut -d '-' -f 1)
if [[ $AK3_DEVICE != $DEVICE_CODE ]] && [[ $DEVICE_CODE == $DEVICE_DEFCONFIG_CODE || $DEVICE_CODE == $COMMON_DEFCONFIG_CODE ]]; then
    sed -i "s/device.name1=.*/device.name1=$DEVICE_CODE/" anykernel.sh
    # sed -i "s/device.name2=.*/device.name2=/" anykernel.sh
    # sed -i "s/device.name3=.*/device.name3=/" anykernel.sh
    # sed -i "s/device.name4=.*/device.name4=/" anykernel.sh
    # sed -i "s/device.name5=.*/device.name5=/" anykernel.sh
    msg "Wrong AnyKernel3 repo detected! Trying to fix it..."
fi
ls $KERNEL_DIR/out/$DEVICE_ARCH/boot/
cp $IMAGE .
cp $DTB $WORKDIR/Anykernel3/dtb
cp $DTBO .

# Archive
mkdir -p $WORKDIR/out
if [[ $KSU_ENABLED == "true" ]]; then
  ZIP_NAME="$KERNEL_NAME-KSU.zip"
else
  ZIP_NAME="$KERNEL_NAME-NonKSU.zip"
fi
TIME=$(TZ='Europe/Berlin' date +"%Y-%m-%d %H:%M:%S")
find ./ * -exec touch -m -d "$TIME" {} \;
zip -r9 $ZIP_NAME *
cp *.zip $WORKDIR/out

# Release Files
cd $WORKDIR/out
msg "Release Files"
echo "
## [$KERNEL_NAME]($README)
- **Time**: $TIME # CET

- **Codename**: $DEVICE_CODE

<br>

- **[Kernel]($KERNEL_SOURCE) Version**: $KERNEL_VERSION
- **[KernelSU]($KERNELSU_SOURCE) Version**: $KERNELSU_VERSION
- **[SuSFS](https://gitlab.com/simonpunk/susfs4ksu) Version**: $SUSFS_VERSION
- **Note**: Use [xx Manager](https://github.com/backslashxx/KernelSU/releases/latest).

<br>

- **[CLANG]($CLANG_SOURCE) Version**: $CLANG_VERSION
- **LLD Version**: $LLD_VERSION
" > bodyFile.md
echo "$TITLE" > name.txt
#echo "$KERNEL_NAME" > name.txt

# Finish
msg "Done"
