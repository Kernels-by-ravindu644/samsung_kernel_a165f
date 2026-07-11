#!/bin/bash
SCRIPT_DIR="$(dirname $(readlink -fq $0))"
KERNEL_VERSION="$(cd kernel-5.10 && make kernelversion 2>/dev/null)"

# init & update git submodules
git submodule update --init --recursive || true

# download & install Samsung's ndk
if [[ ! -d "${SCRIPT_DIR}/kernel/prebuilts" || ! -d "${SCRIPT_DIR}/prebuilts" ]]; then
    echo -e "Cloning Samsung's NDK..."
        curl -LO "https://github.com/Kernels-by-ravindu644/samsung_kernel_a165f/releases/download/toolchain/toolchain.tar.gz" || {
        echo "Failed to download Samsung's NDK. Please check your internet connection and try again." && exit 1
    }
    tar -xf toolchain.tar.gz && rm toolchain.tar.gz
fi

# cleanup before building
rm -rf "${SCRIPT_DIR}/"{out,dist} && \
    mkdir -p "${SCRIPT_DIR}/"{out,dist}

# generate the build.config
cd "${SCRIPT_DIR}/kernel-5.10" && \
    python scripts/gen_build_config.py \
        --kernel-defconfig a16_00_defconfig \
        --kernel-defconfig-overlays entry_level.config \
        -m user \
        -o ../out/target/product/a16/obj/KERNEL_OBJ/build.config && \
        cd "${SCRIPT_DIR}"

# generate localversion
BUILD_VERSION=$(git log -1 --pretty=%h 2>/dev/null)
if [ -z "$BUILD_VERSION" ]; then
    export BUILD_VERSION="dev"
fi
cat << EOF > "${SCRIPT_DIR}/custom_defconfigs/version_defconfig"
CONFIG_LOCALVERSION_AUTO=n
CONFIG_LOCALVERSION="-ravindu644-${BUILD_VERSION}"
EOF

# export environment variables from the samsung's build_kernel.sh
export ARCH=arm64
export PLATFORM_VERSION=13
export CROSS_COMPILE="aarch64-linux-gnu-"
export CROSS_COMPILE_COMPAT="arm-linux-gnueabi-"
export OUT_DIR="../out/target/product/a16/obj/KERNEL_OBJ"
export DIST_DIR="../out/target/product/a16/obj/KERNEL_OBJ"
export BUILD_CONFIG="../out/target/product/a16/obj/KERNEL_OBJ/build.config"

# add custom build options to here
# checkout kernel/build/build.sh to possible variables
GKI_KERNEL_BUILD_OPTIONS=(
    "LTO=thin"
    "SKIP_MRPROPER=1"
    "KMI_SYMBOL_LIST_STRICT_MODE=0"
    "ABI_DEFINITION="
    "BUILD_BOOT_IMG=1"
    "MKBOOTIMG_PATH=${SCRIPT_DIR}/tools/mkbootimg/mkbootimg.py"
    "KERNEL_BINARY=kernel-5.10/arch/arm64/boot/Image.gz"
    "BOOT_IMAGE_HEADER_VERSION=4"
    "SKIP_VENDOR_BOOT=1"
    "AVB_SIGN_BOOT_IMG=1"
    "AVB_BOOT_PARTITION_SIZE=67108864"
    "AVB_BOOT_KEY=${SCRIPT_DIR}/tools/mkbootimg/tests/data/testkey_rsa2048.pem"
    "AVB_BOOT_ALGORITHM=SHA256_RSA2048"
    "AVB_BOOT_PARTITION_NAME=boot"
    "GKI_RAMDISK_PREBUILT_BINARY=${SCRIPT_DIR}/ramdisk-prebuilt/gki-ramdisk.lz4"
)
# mkbootimg extra args to build the boot.img
export MKBOOTIMG_EXTRA_ARGS="
    --os_version 12.0.0 \
    --os_patch_level 2025-05-00 \
    --pagesize 4096 \
"

# run menuconfig only if you want to.
export MAKE_MENUCONFIG=0
if [ "$MAKE_MENUCONFIG" = "1" ]; then
    export HERMETIC_TOOLCHAIN=0
fi

# custom defconfigs support
export MERGE_CONFIG="${SCRIPT_DIR}/kernel-5.10/scripts/kconfig/merge_config.sh"
if [ -d "${SCRIPT_DIR}/custom_defconfigs" ]; then
    CUSTOM_DEFCONFIGS_LIST=$(find "${SCRIPT_DIR}/custom_defconfigs" -maxdepth 1 -type f -exec realpath {} \; | tr '\n' ' ')
else
    CUSTOM_DEFCONFIGS_LIST=""
fi
export CUSTOM_DEFCONFIGS_LIST

# build the kernel
build_kernel(){
    cd "${SCRIPT_DIR}/kernel"

    env "${GKI_KERNEL_BUILD_OPTIONS[@]}" ./build/build.sh && \
        cp \
        "${SCRIPT_DIR}/out/target/product/a16/obj/KERNEL_OBJ/kernel-5.10/arch/arm64/boot/Image.gz" \
        "${SCRIPT_DIR}/out/target/product/a16/obj/KERNEL_OBJ/boot.img" \
        "${SCRIPT_DIR}/dist"
    local status=$?

    cd "${SCRIPT_DIR}"
    return $status
}

pack_kernel() {
    cd "${SCRIPT_DIR}/dist"

    tar -cf "Droidspaces-KSUN-SuSFS-SM-A165F-${KERNEL_VERSION}-${BUILD_VERSION}.tar" boot.img && \
        zip -9 "Droidspaces-KSUN-SuSFS-SM-A165F-${KERNEL_VERSION}-${BUILD_VERSION}.tar.zip" \
        "Droidspaces-KSUN-SuSFS-SM-A165F-${KERNEL_VERSION}-${BUILD_VERSION}.tar" && \
        rm -f "Droidspaces-KSUN-SuSFS-SM-A165F-${KERNEL_VERSION}-${BUILD_VERSION}.tar" boot.img

    cd "${SCRIPT_DIR}"
}

build_kernel && \
    pack_kernel
