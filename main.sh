#!/usr/bin/env sh
# SPDX-License-Identifier: GPL-2.0-only

set -e
set -o pipefail

# Changable Data
# ------------------------------------------------------------

# Kernel
KERNEL_NAME="Protium"
KERNEL_GIT="https://github.com/gawasvedraj/kernel_xiaomi_stone.git"
KERNEL_BRANCH="master"

# KernelSU
KERNELSU_REPO="backslashxx/KernelSU"
KERNELSU_BRANCH="master"
VB_ENABLED="false"

# Anykernel3
ANYKERNEL3_GIT="https://github.com/gawasvedraj/AnyKernel3.git"
ANYKERNEL3_BRANCH="stone"

# Build
DEVICE_CODE="stone"
DEVICE_DEFCONFIG="moonstone_defconfig"
COMMON_DEFCONFIG=""
DEVICE_ARCH="arch/arm64"

# Clang
CLANG_DL="https://github.com/bachnxuan/aosp_clang_mirror/releases/download/clang-r596125-15071444/clang-r596125.tar.gz"

# ------------------------------------------------------------

# Input Variables
if [[ $1 == "VB" ]]; then
    VB_ENABLED="true"
    echo "Input changed VB_ENABLED to true"
elif [[ $1 == "NonVB" ]]; then
    VB_ENABLED="false"
    echo "Input changed VB_ENABLED to false"
fi

if [[ $2 == *.git ]]; then
    KERNEL_GIT=$2
    echo "Input changed KERNEL_GIT"
fi

# Set variables
WORKDIR="$(pwd)"

CLANG_DIR="$WORKDIR/Clang/bin"

KERNEL_REPO="${KERNEL_GIT::-4}/"
KERNEL_SOURCE="${KERNEL_REPO::-1}/tree/$KERNEL_BRANCH"
KERNEL_DIR="$WORKDIR/$KERNEL_NAME"

KERNELSU_SOURCE="https://github.com/$KERNELSU_REPO"
README="https://github.com/gawasvedraj/KernelOwO/blob/master/README.md"

DEVICE_DEFCONFIG_FILE="$KERNEL_DIR/$DEVICE_ARCH/configs/$DEVICE_DEFCONFIG"
IMAGE="$KERNEL_DIR/out/$DEVICE_ARCH/boot/Image"
DTB="$KERNEL_DIR/out/$DEVICE_ARCH/boot/dtb.img"
DTBO="$KERNEL_DIR/out/$DEVICE_ARCH/boot/dtbo.img"

export KBUILD_BUILD_USER=vedu
export KBUILD_BUILD_HOST=kbuild

# Highlight
msg() {
	echo
	echo -e "\e[1;33m$*\e[0m"
	echo
}

cd $WORKDIR

# Setup
msg "Setup"
git config --global http.postBuffer 524288000

msg "Cloning Clang and Kernel in parallel..."

# Kernel
(
    git clone --depth=1 $KERNEL_GIT --single-branch -b $KERNEL_BRANCH $KERNEL_DIR
) &
KERNEL_PID=$!

# Clang
(
    mkdir -p Clang
    aria2c -s16 -x16 -k1M $CLANG_DL -o Clang.tar.gz
    tar -C Clang/ -zxf Clang.tar.gz
    rm -f Clang.tar.gz
) &
CLANG_PID=$!

wait $KERNEL_PID $CLANG_PID
msg "Clone completed"

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
ls $KERNEL_DIR/out/$DEVICE_ARCH/boot/
cp $IMAGE .
cp $DTB ./dtb
cp $DTBO ./dtbo

# Archive
mkdir -p $WORKDIR/out
if [[ $VB_ENABLED == "true" ]]; then
  ZIP_NAME="$KERNEL_NAME-VB.zip"
else
  ZIP_NAME="$KERNEL_NAME-NonVB.zip"
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

- **[Kernel](https://www.youtube.com/watch?v=xvFZjo5PgG0) Version**: $KERNEL_VERSION
- **[KernelSU]($KERNELSU_SOURCE) Version**: $KERNELSU_VERSION

<br>

- **KowSU Manager**: [Latest](https://t.me/kowsu_build)
- **Official Manager**: [Latest](https://github.com/tiann/KernelSU/releases/latest)
" > bodyFile.md
echo "$TITLE" > name.txt
#echo "$KERNEL_NAME" > name.txt

# Finish
msg "Done"
