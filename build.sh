#!/bin/bash
SCRIPT_DIR="$(dirname $(readlink -fq $0))"

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
)

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
        "${SCRIPT_DIR}/dist"
    local status=$?

    cd "${SCRIPT_DIR}"
    return $status
}

build_kernel
