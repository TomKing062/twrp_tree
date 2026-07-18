# Copyright (C) 2026 The TWRP Open Source Project
#
# SPDX-License-Identifier: Apache-2.0

$(call inherit-product, $(SRC_TARGET_DIR)/product/aosp_base.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/core_64_bit.mk)
$(call inherit-product-if-exists, $(SRC_TARGET_DIR)/product/gsi_keys.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/full_base_telephony.mk)

$(call inherit-product-if-exists, $(SRC_TARGET_DIR)/product/virtual_ab_ota.mk)
$(call inherit-product-if-exists, vendor/twrp/config/common.mk)

$(call inherit-product, device/nubia/P780F01/device.mk)

PRODUCT_EXTRA_RECOVERY_KEYS += \
    device/nubia/P780F01/security/releasekey
PRODUCT_DEVICE := P780F01
PRODUCT_NAME := twrp_P780F01
PRODUCT_BRAND := nubia
PRODUCT_MODEL := nubia Z2464N
PRODUCT_MANUFACTURER := nubia
PRODUCT_RELEASE_NAME := P780F01

PRODUCT_BUILD_PROP_OVERRIDES += \
    PRIVATE_BUILD_DESC="ums9632_1h10_64only-user 15 AP3A.240905.015.A2 20260522.013409 release-keys"

BUILD_FINGERPRINT := nubia/P780F01/P780F01:15/AP3A.240905.015.A2/20260522.013409:user/release-keys
