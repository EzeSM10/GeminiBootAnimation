#!/usr/bin/env bash
# Build installable packages with an early, systemless mounting script.
set -euo pipefail

VERSION=$(sed -n 's/^version=//p' module.prop)
OUT="dist"
mkdir -p "$OUT"

build_variant() {
    local variant="$1" description="$2" extra_targets="$3"
    local task_tmp
    task_tmp=$(mktemp -d)
    mkdir -p "$task_tmp/META-INF/com/google/android" "$task_tmp/files"
    cp META-INF/com/google/android/update-binary META-INF/com/google/android/updater-script \
        "$task_tmp/META-INF/com/google/android/"
    cp LICENSE customize.sh post-fs-data.sh "$task_tmp/"
    sed "s|^description=.*|description=$description|" module.prop > "$task_tmp/module.prop"
    cp system/media/bootanimation.zip system/media/bootanimation-dark.zip "$task_tmp/files/"
    printf '%s\n' /product/media /system/media > "$task_tmp/mount-targets.txt"
    if [ -n "$extra_targets" ]; then
        printf '%s\n' "$extra_targets" >> "$task_tmp/mount-targets.txt"
    fi
    chmod 755 "$task_tmp/post-fs-data.sh" "$task_tmp/META-INF/com/google/android/update-binary"
    (cd "$task_tmp" && zip -qr9 - .) > "$OUT/GeminiBootAnimation-${variant}-${VERSION}.zip"
    rm -rf "$task_tmp"
    echo "Built: $OUT/GeminiBootAnimation-${variant}-${VERSION}.zip"
}

build_variant standard "Gemini Boot Animation — Standard (Pixel / AOSP / OnePlus / Realme)" ""
build_variant MIUI "Gemini Boot Animation — Xiaomi MIUI" $'/system_ext/media\n/system/media/theme'
build_variant MTK "Gemini Boot Animation — MediaTek" /custom/media
build_variant Motorola "Gemini Boot Animation — Motorola" /oem/media
build_variant EMUI "Gemini Boot Animation — Huawei EMUI" /system/etc/media
