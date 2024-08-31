#
# Copyright (C) 2024 The Android Open Source Project
# Copyright (C) 2024 SebaUbuntu's TWRP device tree generator
#
# SPDX-License-Identifier: Apache-2.0
#

# Inherit from those products. Most specific first.
$(call inherit-product, $(SRC_TARGET_DIR)/product/core_64_bit.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/full_base_telephony.mk)

# Inherit some common Omni stuff.
$(call inherit-product, vendor/omni/config/common.mk)

# Inherit from S701 device
$(call inherit-product, device/philips/S701/device.mk)

PRODUCT_DEVICE := S701
PRODUCT_NAME := omni_S701
PRODUCT_BRAND := Philips
PRODUCT_MODEL := Xenium S701
PRODUCT_MANUFACTURER := philips

PRODUCT_GMS_CLIENTID_BASE := android-philips

PRODUCT_BUILD_PROP_OVERRIDES += \
    PRIVATE_BUILD_DESC="full_g1930fua_q6532-user 9 PPR1.180610.011 1638444763 release-keys"

BUILD_FINGERPRINT := Philips/S701/S701:9/PPR1.180610.011/1638444763:user/release-keys
