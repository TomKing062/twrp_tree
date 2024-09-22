#
# Copyright (C) 2024 The Android Open Source Project
# Copyright (C) 2024 SebaUbuntu's TWRP device tree generator
#
# SPDX-License-Identifier: Apache-2.0
#

patch -Np1 < device/philips/S701/check_radio_versions.py.patch
patch -Np1 < device/philips/S701/post_process_props.py.patch

add_lunch_combo omni_S701-eng
