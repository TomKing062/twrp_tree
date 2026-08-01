#!/system/bin/sh

# Read the active system and vendor patch levels before TWRP data decrypt and
# publish the values Keymaster/KeyMint uses for its OS configuration.

LOG_TAG="prepdecrypt"
SYSTEM_ROOT="/system_root"
SYSTEM_WAIT_SECONDS=30

# Use the mounted system build.prop as platform SPL by default. Set this to 1
# only when trying to decrypt data that was created under the original stock ROM.
USE_VENDOR_SPL_FOR_PLATFORM=0

# KeyMint receives platform, vendor, and boot patch levels independently. A GSI
# replaces only system, so leave the vendor patch level sourced from /vendor.
# Set this only for a device whose stock KeyMint explicitly requires it.
ALIGN_VENDOR_SPL_WITH_PLATFORM=0

# Leave empty for auto-detect. Set to a date such as 2099-12-31 for testing a
# key blob that may have been upgraded under a higher patch level before.
FORCE_SECURITY_PATCH=""

# Unmount only mountpoints that this script mounted by itself.
UNMOUNT_SYSTEM_ROOT_AFTER_READ=1
UNMOUNT_VENDOR_AFTER_READ=1
MOUNTED_SYSTEM_ROOT=0
MOUNTED_VENDOR=0

logi() {
    echo "$LOG_TAG: $*"
    command -v log >/dev/null 2>&1 && log -t "$LOG_TAG" "$*" >/dev/null 2>&1
}

is_mounted() {
    grep -q " $1 " /proc/mounts 2>/dev/null
}

try_mount_dev() {
    dev="$1"
    mnt="$2"

    [ -b "$dev" ] || return 1
    mkdir -p "$mnt" 2>/dev/null

    for fs in erofs ext4 f2fs; do
        mount -t "$fs" -o ro "$dev" "$mnt" >/dev/null 2>&1 && return 0
    done

    mount -o ro "$dev" "$mnt" >/dev/null 2>&1 && return 0
    return 1
}

mount_system_root() {
    mkdir -p "$SYSTEM_ROOT" 2>/dev/null
    is_mounted "$SYSTEM_ROOT" && return 0

    mount "$SYSTEM_ROOT" >/dev/null 2>&1 && {
        MOUNTED_SYSTEM_ROOT=1
        return 0
    }
    mount -o ro "$SYSTEM_ROOT" >/dev/null 2>&1 && {
        MOUNTED_SYSTEM_ROOT=1
        return 0
    }

    slot="$(getprop ro.boot.slot_suffix 2>/dev/null)"
    for dev in \
        "/dev/block/mapper/system$slot" \
        "/dev/block/mapper/system" \
        "/dev/block/by-name/system$slot" \
        "/dev/block/by-name/system" \
        "/dev/block/platform/bootdevice/by-name/system$slot" \
        "/dev/block/platform/bootdevice/by-name/system"; do
        try_mount_dev "$dev" "$SYSTEM_ROOT" && {
            MOUNTED_SYSTEM_ROOT=1
            return 0
        }
    done

    return 1
}

wait_for_system_root() {
    attempt=0
    while [ "$attempt" -lt "$SYSTEM_WAIT_SECONDS" ]; do
        if mount_system_root; then
            return 0
        fi
        attempt=$((attempt + 1))
        sleep 1
    done

    logi "warning: timed out waiting for the active system image"
    return 1
}

mount_vendor() {
    [ -d /vendor ] || mkdir -p /vendor 2>/dev/null
    is_mounted /vendor && return 0

    mount /vendor >/dev/null 2>&1 && {
        MOUNTED_VENDOR=1
        return 0
    }
    mount -o ro /vendor >/dev/null 2>&1 && {
        MOUNTED_VENDOR=1
        return 0
    }

    slot="$(getprop ro.boot.slot_suffix 2>/dev/null)"
    for dev in \
        "/dev/block/mapper/vendor$slot" \
        "/dev/block/mapper/vendor" \
        "/dev/block/by-name/vendor$slot" \
        "/dev/block/by-name/vendor" \
        "/dev/block/platform/bootdevice/by-name/vendor$slot" \
        "/dev/block/platform/bootdevice/by-name/vendor"; do
        try_mount_dev "$dev" /vendor && {
            MOUNTED_VENDOR=1
            return 0
        }
    done

    return 1
}

read_prop_file() {
    key="$1"
    shift

    for file in "$@"; do
        [ -r "$file" ] || continue
        value="$(sed -n "s/^$key=//p" "$file" 2>/dev/null | head -n 1 | tr -d '\r')"
        [ -n "$value" ] && {
            echo "$value"
            return 0
        }
    done

    return 1
}

valid_date_prop() {
    value="$1"
    y="${value%%-*}"
    rest="${value#*-}"
    m="${rest%%-*}"
    d="${rest#*-}"

    [ "$value" != "$rest" ] || return 1
    [ "$rest" != "$d" ] || return 1
    case "$y$m$d" in
        *[!0-9]*|"") return 1 ;;
    esac
    [ ${#y} -eq 4 ] && [ ${#m} -eq 2 ] && [ ${#d} -eq 2 ]
}

set_android_prop() {
    key="$1"
    value="$2"

    [ -n "$value" ] || return 1

    if command -v resetprop >/dev/null 2>&1; then
        resetprop -n "$key" "$value" >/dev/null 2>&1 || resetprop "$key" "$value" >/dev/null 2>&1
    else
        setprop "$key" "$value" >/dev/null 2>&1
    fi

    current="$(getprop "$key" 2>/dev/null)"
    [ "$current" = "$value" ] && return 0

    logi "failed to set $key=$value (current: '$current')"
    return 1
}

cleanup_mounts() {
    if [ "$UNMOUNT_VENDOR_AFTER_READ" = "1" ] && [ "$MOUNTED_VENDOR" = "1" ] && is_mounted /vendor; then
        if umount /vendor >/dev/null 2>&1; then
            logi "unmounted /vendor"
        else
            logi "warning: failed to unmount /vendor"
        fi
    fi

    if [ "$UNMOUNT_SYSTEM_ROOT_AFTER_READ" = "1" ] && [ "$MOUNTED_SYSTEM_ROOT" = "1" ] && is_mounted "$SYSTEM_ROOT"; then
        if umount "$SYSTEM_ROOT" >/dev/null 2>&1; then
            logi "unmounted $SYSTEM_ROOT"
        else
            logi "warning: failed to unmount $SYSTEM_ROOT"
        fi
    fi
}

wait_for_system_root
mount_vendor >/dev/null 2>&1

SYSTEM_BUILD_PROP="$SYSTEM_ROOT/system/build.prop"
[ -r "$SYSTEM_BUILD_PROP" ] || SYSTEM_BUILD_PROP="$SYSTEM_ROOT/build.prop"
[ -r "$SYSTEM_BUILD_PROP" ] || SYSTEM_BUILD_PROP="/system/build.prop"

VENDOR_BUILD_PROP="/vendor/build.prop"
[ -r "$VENDOR_BUILD_PROP" ] || VENDOR_BUILD_PROP="$SYSTEM_ROOT/vendor/build.prop"

system_spl="$(read_prop_file ro.build.version.security_patch \
    "$SYSTEM_BUILD_PROP" \
    "$SYSTEM_ROOT/system/system/build.prop" \
    /system/build.prop)"

# /vendor may already be mounted by recovery. Keep its original value as a
# fallback instead of substituting the GSI's platform patch level.
recovery_vendor_spl="$(getprop ro.vendor.build.security_patch 2>/dev/null)"
vendor_spl="$(read_prop_file ro.vendor.build.security_patch \
    "$VENDOR_BUILD_PROP" \
    "$SYSTEM_BUILD_PROP" \
    "$SYSTEM_ROOT/system/vendor/build.prop")"

if ! valid_date_prop "$vendor_spl" && valid_date_prop "$recovery_vendor_spl"; then
    vendor_spl="$recovery_vendor_spl"
    logi "using existing vendor SPL: $vendor_spl"
fi

if valid_date_prop "$vendor_spl" && [ "$USE_VENDOR_SPL_FOR_PLATFORM" = "1" ]; then
    platform_spl="$vendor_spl"
    [ "$system_spl" != "$platform_spl" ] && logi "using vendor SPL for platform: $platform_spl (system has '$system_spl')"
else
    platform_spl="$system_spl"
fi

if [ "$ALIGN_VENDOR_SPL_WITH_PLATFORM" = "1" ]; then
    [ "$vendor_spl" != "$platform_spl" ] && logi "aligning vendor SPL with platform: $platform_spl (vendor has '$vendor_spl')"
    vendor_spl="$platform_spl"
fi

if valid_date_prop "$FORCE_SECURITY_PATCH"; then
    platform_spl="$FORCE_SECURITY_PATCH"
    vendor_spl="$FORCE_SECURITY_PATCH"
    logi "forcing platform/vendor SPL: $FORCE_SECURITY_PATCH"
fi

release="$(read_prop_file ro.build.version.release "$SYSTEM_BUILD_PROP" /system/build.prop "$VENDOR_BUILD_PROP")"
sdk="$(read_prop_file ro.build.version.sdk "$SYSTEM_BUILD_PROP" /system/build.prop "$VENDOR_BUILD_PROP")"

if ! valid_date_prop "$platform_spl"; then
    logi "invalid or missing platform security patch: '$platform_spl'"
    cleanup_mounts
    setprop twrp.prepdecrypt.ready 1
    exit 0
fi

if ! valid_date_prop "$vendor_spl"; then
    logi "invalid or missing vendor security patch: '$vendor_spl'"
fi

props_ok=1

set_android_prop ro.build.version.security_patch "$platform_spl" || props_ok=0
set_android_prop ro.system.build.version.security_patch "$platform_spl" || props_ok=0
set_android_prop ro.product.build.version.security_patch "$platform_spl" >/dev/null 2>&1
set_android_prop ro.system_ext.build.version.security_patch "$platform_spl" >/dev/null 2>&1
set_android_prop ro.vendor.build.security_patch "$vendor_spl" || props_ok=0
set_android_prop ro.vendor.build.version.security_patch "$vendor_spl" >/dev/null 2>&1

[ -n "$release" ] && {
    set_android_prop ro.build.version.release "$release" || props_ok=0
    set_android_prop ro.system.build.version.release "$release" || props_ok=0
    set_android_prop ro.product.build.version.release "$release" >/dev/null 2>&1
    set_android_prop ro.system_ext.build.version.release "$release" >/dev/null 2>&1
    set_android_prop ro.build.version.release_or_codename "$release" >/dev/null 2>&1
    set_android_prop ro.system.build.version.release_or_codename "$release" >/dev/null 2>&1
    set_android_prop ro.product.build.version.release_or_codename "$release" >/dev/null 2>&1
    set_android_prop ro.system_ext.build.version.release_or_codename "$release" >/dev/null 2>&1
}

[ -n "$sdk" ] && {
    set_android_prop ro.build.version.sdk "$sdk" || props_ok=0
    set_android_prop ro.system.build.version.sdk "$sdk" || props_ok=0
    set_android_prop ro.product.build.version.sdk "$sdk" >/dev/null 2>&1
    set_android_prop ro.system_ext.build.version.sdk "$sdk" >/dev/null 2>&1
}

logi "platform security patch: $platform_spl"
logi "vendor security patch: $vendor_spl"
[ -n "$release" ] && logi "android release: $release"
[ -n "$sdk" ] && logi "android sdk: $sdk"

if [ "$props_ok" != "1" ]; then
    logi "not setting crypto.ready because one or more properties failed"
    cleanup_mounts
    setprop twrp.prepdecrypt.ready 1
    exit 0
fi

cleanup_mounts

# KeyMint must start only after its OS version and patch properties describe
# the active system. The init rule also waits for the Trusty storage proxies.
setprop twrp.prepdecrypt.ready 1

setprop crypto.ready 1 >/dev/null 2>&1
if [ "$(getprop crypto.ready 2>/dev/null)" = "1" ]; then
    logi "crypto.ready=1"
else
    logi "failed to set crypto.ready=1"
fi

exit 0
