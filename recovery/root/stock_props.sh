#!/system/bin/sh

RESETPROP=/system/bin/resetprop

[ -x "$RESETPROP" ] || exit 0

set_prop() {
    "$RESETPROP" -n "$1" "$2"
}

set_build_props() {
    part="$1"
    release="$2"
    sdk="$3"
    incremental="$4"
    fingerprint="$5"
    security_patch="$6"

    if [ -z "$part" ]; then
        base=ro.build
    else
        base=ro."$part".build
    fi

    set_prop "$base.fingerprint" "$fingerprint"
    set_prop "$base.version.incremental" "$incremental"
    set_prop "$base.version.release" "$release"
    set_prop "$base.version.release_or_codename" "$release"
    set_prop "$base.version.sdk" "$sdk"
    set_prop "$base.version.security_patch" "$security_patch"
}

OS_FINGERPRINT=nubia/P780F01/P780F01:15/AP3A.240905.015.A2/20260522.013409:user/release-keys
OS_INCREMENTAL=20260522
OS_SECURITY_PATCH=2026-05-05

VENDOR_FINGERPRINT=nubia/P780F01/P780F01:15/AP3A.240905.015.A2/20260522.013409:user/release-keys
VENDOR_INCREMENTAL=20260522.013408
VENDOR_SECURITY_PATCH=2026-05-05

BOOT_SECURITY_PATCH=2026-05-05

set_build_props "" 15 35 "$OS_INCREMENTAL" "$OS_FINGERPRINT" "$OS_SECURITY_PATCH"
set_build_props product 15 35 "$OS_INCREMENTAL" "$OS_FINGERPRINT" "$OS_SECURITY_PATCH"
set_build_props system 15 35 "$OS_INCREMENTAL" "$OS_FINGERPRINT" "$OS_SECURITY_PATCH"
set_build_props system_ext 15 35 "$OS_INCREMENTAL" "$OS_FINGERPRINT" "$OS_SECURITY_PATCH"

set_build_props bootimage 15 35 "$VENDOR_INCREMENTAL" "$VENDOR_FINGERPRINT" "$BOOT_SECURITY_PATCH"
set_build_props odm 15 35 "$VENDOR_INCREMENTAL" "$VENDOR_FINGERPRINT" "$VENDOR_SECURITY_PATCH"
set_build_props vendor 15 35 "$VENDOR_INCREMENTAL" "$VENDOR_FINGERPRINT" "$VENDOR_SECURITY_PATCH"

set_prop ro.product.first_api_level 35
set_prop ro.vendor.build.security_patch "$VENDOR_SECURITY_PATCH"
