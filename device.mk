# Copyright (C) 2026 The TWRP Open Source Project
#
# SPDX-License-Identifier: Apache-2.0

LOCAL_PATH := device/nubia/P780F01

PRODUCT_USE_DYNAMIC_PARTITIONS := true
PRODUCT_VIRTUAL_AB_OTA := true

PRODUCT_COPY_FILES += \
    $(call find-copy-subdir-files,*,$(LOCAL_PATH)/recovery/root,vendor_ramdisk)

# Filesystem tools.
PRODUCT_PACKAGES += \
    check_f2fs \
    dump.erofs \
    f2fs_io \
    fsck.erofs \
    sg_write_buffer

# Host filesystem tools.
PRODUCT_HOST_PACKAGES += \
    mkfs.erofs

# Userdata checkpoint / snapshots.
PRODUCT_PACKAGES += \
    checkpoint_gc \
    snapuserd

# Fastbootd
PRODUCT_PACKAGES += \
    android.hardware.fastboot@1.0-impl-mock \
    android.hardware.fastboot@1.0-impl-mock.recovery \
    fastbootd
