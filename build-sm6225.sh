#!/usr/bin/env bash
set -euo pipefail

DEVICE="${1:-devon}"
KERNEL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOP_DIR="$(cd "$KERNEL_DIR/.." && pwd)"
DT_DIR="$TOP_DIR/android_kernel_motorola_sm6225-devicetrees"
OUT_DIR="${OUT_DIR:-$KERNEL_DIR/out-$DEVICE}"
JOBS="${JOBS:-$(nproc)}"

case "$DEVICE" in
    devon|hawao|rhode|fogona) ;;
    *)
        echo "Unsupported device: $DEVICE (expected: devon, hawao, rhode, fogona)" >&2
        exit 1
        ;;
esac

if [ ! -d "$DT_DIR/qcom" ]; then
    echo "Missing devicetrees repo at $DT_DIR" >&2
    exit 1
fi

if [ ! -e "$KERNEL_DIR/arch/arm64/boot/dts/vendor" ]; then
    ln -s ../../../../../android_kernel_motorola_sm6225-devicetrees \
        "$KERNEL_DIR/arch/arm64/boot/dts/vendor"
fi

mkdir -p "$OUT_DIR"

KCONFIG_CONFIG="$OUT_DIR/.config" "$KERNEL_DIR/scripts/kconfig/merge_config.sh" -m -O "$OUT_DIR" \
    "$KERNEL_DIR/arch/arm64/configs/gki_defconfig" \
    "$KERNEL_DIR/arch/arm64/configs/vendor/bengal_GKI.config" \
    "$KERNEL_DIR/arch/arm64/configs/vendor/ext_config/moto-bengal.config" \
    "$KERNEL_DIR/arch/arm64/configs/vendor/ext_config/moto-bengal-${DEVICE}.config"

make -C "$KERNEL_DIR" O="$OUT_DIR" ARCH=arm64 LLVM=1 -j"$JOBS" olddefconfig
make -C "$KERNEL_DIR" O="$OUT_DIR" ARCH=arm64 LLVM=1 MSM_ARCH=bengal -j"$JOBS" Image dtbs
