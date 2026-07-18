# Copyright (C) 2026 The TWRP Open Source Project
#
# SPDX-License-Identifier: Apache-2.0

LOCAL_PATH := $(call my-dir)

ifeq ($(TARGET_DEVICE),P780F01)
include $(call all-subdir-makefiles,$(LOCAL_PATH))
endif
