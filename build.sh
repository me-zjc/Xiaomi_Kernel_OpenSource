#!/usr/bin/env bash
#
# Copyright (C) 2024 chao
#
# Simple Local Kernel Build Script
#
# Configured for Redmi Note 8 / ginkgo custom kernel source

SECONDS=0 # builtin bash timer
ZIPNAME="Kernel-Ginkgo-$(TZ=Asia/Shanghai date +"%Y%m%d-%H%M").zip"
TC_DIR="/workspace/toolchain/linux-x86"
CLANG_DIR="$TC_DIR/clang-r416183b"
GCC_64_DIR="/workspace/toolchain/aarch64-linux-android-4.9"
GCC_32_DIR="/workspace/toolchain/arm-linux-androideabi-4.9"
AK3_DIR="/workspace/AnyKernel3"
DEFCONFIG="vendor/ginkgo-perf_defconfig"
MAKE_PARAMS="O=out ARCH=arm64 CC=clang AR=llvm-ar AS=llvm-as NM=llvm-nm \
        OBJCOPY=llvm-objcopy OBJDUMP=llvm-objdump STRIP=llvm-strip \
        CLANG_TRIPLE=aarch64-linux-gnu- \
        CROSS_COMPILE=$GCC_64_DIR/bin/aarch64-linux-android- \
        CROSS_COMPILE_ARM32=$GCC_32_DIR/bin/arm-linux-androideabi-"
export PATH="$CLANG_DIR/bin:$PATH"
export KBUILD_BUILD_USER="chao"
export KBUILD_BUILD_HOST="BUILD_DOCKER"
export KBUILD_BUILD_VERSION="1"

if ! [ -d "${CLANG_DIR}" ]; then
echo "Clang not found! Cloning to ${TC_DIR}..."
if ! git clone --depth=1 https://github.com/me-zjc/android_prebuilts_clang_kernel_linux-x86_clang-r416183b.git ${CLANG_DIR}; then
echo "Cloning failed! Aborting..."
exit 1
fi
fi

if ! [ -d "${GCC_64_DIR}" ]; then
echo "gcc not found! Cloning to ${GCC_64_DIR}..."
if ! git clone --depth=1 -b lineage-19.1 https://github.com/me-zjc/android_prebuilts_gcc_linux-x86_aarch64_aarch64-linux-android-4.9.git ${GCC_64_DIR}; then
echo "Cloning failed! Aborting..."
exit 1
fi
fi

if ! [ -d "${GCC_32_DIR}" ]; then
echo "gcc_32 not found! Cloning to ${GCC_32_DIR}..."
if ! git clone --depth=1 -b lineage-19.1 https://github.com/me-zjc/android_prebuilts_gcc_linux-x86_arm_arm-linux-androideabi-4.9.git ${GCC_32_DIR}; then
echo "Cloning failed! Aborting..."
exit 1
fi
fi

if [[ $1 = "-r" || $1 = "--regen" ]]; then
make O=out ARCH=arm64 $DEFCONFIG savedefconfig
cp out/defconfig arch/arm64/configs/$DEFCONFIG
exit
fi

if [[ $1 = "-c" || $1 = "--clean" ]]; then
rm -rf out
fi

mkdir -p out
#make $MAKE_PARAMS menuconfig
make $MAKE_PARAMS $DEFCONFIG

echo -e "\nStarting compilation...\n"
make -j$(nproc --all) $MAKE_PARAMS Image.gz-dtb
if [ -f "out/arch/arm64/boot/Image.gz-dtb" ]; then
echo -e "\nKernel compiled succesfully!"
else
echo -e "\nKernel compiled failure!"
exit 1
fi

