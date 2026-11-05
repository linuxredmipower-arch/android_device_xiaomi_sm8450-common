#
# Copyright (C) 2021 The Android Open Source Project
#           (C) 2022-2023 Paranoid Android
#
# SPDX-License-Identifier: Apache-2.0
#

COMMON_PATH := device/xiaomi/sm8450-common
HARDWARE_PATH := hardware/xiaomi

# Architecture
TARGET_ARCH := arm64
TARGET_ARCH_VARIANT := armv8-2a-dotprod
TARGET_CPU_ABI := arm64-v8a
TARGET_CPU_VARIANT := kryo785

# A/B
AB_OTA_UPDATER := true
AB_OTA_PARTITIONS += \
    boot \
    dtbo \
    odm \
    product \
    recovery \
    system \
    system_ext \
    vbmeta \
    vbmeta_system \
    vendor \
    vendor_boot \
    vendor_dlkm

# Bootloader
TARGET_BOOTLOADER_BOARD_NAME ?= taro

# Build
BUILD_BROKEN_DUP_RULES := true
BUILD_BROKEN_ELF_PREBUILT_PRODUCT_COPY_FILES  := true
BUILD_BROKEN_VENDOR_PROPERTY_NAMESPACE := true

# Camera
TARGET_CAMERA_SERVICE_EXT_LIB := //$(COMMON_PATH):libcameraservice_extension.xiaomi_taro

# HIDL
DEVICE_FRAMEWORK_COMPATIBILITY_MATRIX_FILE += $(HARDWARE_PATH)/vintf/xiaomi_framework_compatibility_matrix.xml
DEVICE_FRAMEWORK_COMPATIBILITY_MATRIX_FILE += vendor/qcom/opensource/core-utils/vendor_framework_compatibility_matrix.xml
DEVICE_FRAMEWORK_COMPATIBILITY_MATRIX_FILE += $(COMMON_PATH)/vintf/compatibility_matrix.xml
DEVICE_MATRIX_FILE := hardware/qcom-caf/common/compatibility_matrix.xml
DEVICE_MANIFEST_FILE += $(COMMON_PATH)/configs/hidl/manifest.xml
ifeq ($(TARGET_NFC_SKU),)
DEVICE_MANIFEST_FILE += $(COMMON_PATH)/configs/hidl/manifest_nfc.xml
else
ODM_MANIFEST_SKUS += $(TARGET_NFC_SKU)
$(foreach sku, $(call to-upper, $(TARGET_NFC_SKU)), \
    $(eval ODM_MANIFEST_$(sku)_FILES := $(COMMON_PATH)/configs/hidl/manifest_nfc.xml))
endif

# Kernel
BOARD_KERNEL_PAGESIZE := 4096
BOARD_INCLUDE_DTB_IN_BOOTIMG := true
BOARD_RAMDISK_USE_LZ4 := true
BOARD_USES_GENERIC_KERNEL_IMAGE := true
TARGET_HAS_GENERIC_KERNEL_HEADERS := true

BOARD_BOOT_HEADER_VERSION := 4
BOARD_MKBOOTIMG_ARGS := --header_version $(BOARD_BOOT_HEADER_VERSION)

BOARD_KERNEL_CMDLINE := \
    mtdoops.fingerprint=$(AOSPA_VERSION) \
    swinfo.fingerprint=$(AOSPA_VERSION) \
    allow_file_spec_access \
    irqaffinity=0-3 \
    pelt=8

BOARD_BOOTCONFIG := \
    androidboot.hardware=qcom \
    androidboot.init_fatal_reboot_target=recovery \
    androidboot.memcg=1 \
    androidboot.usbcontroller=a600000.dwc3 \
    # androidboot.selinux=permissive

# DEBUG R1-b (2026-11-04): permissive boot to isolate SELinux denials.
# Remove before release; see round16/pixelos_aospa_completion_plan.md.
BOARD_BOOTCONFIG += androidboot.selinux=permissive

# Partitions
BOARD_FLASH_BLOCK_SIZE := 131072
BOARD_BOOTIMAGE_PARTITION_SIZE := 201326592
BOARD_VENDOR_BOOTIMAGE_PARTITION_SIZE := 100663296
BOARD_DTBOIMG_PARTITION_SIZE := 25165824
BOARD_RECOVERYIMAGE_PARTITION_SIZE := 104857600
BOARD_USES_METADATA_PARTITION := true
BOARD_USES_VENDOR_DLKMIMAGE := true

BOARD_SUPER_PARTITION_SIZE ?= 9126805504
BOARD_SUPER_PARTITION_GROUPS := qti_dynamic_partitions
BOARD_QTI_DYNAMIC_PARTITIONS_PARTITION_LIST := odm product system system_ext vendor vendor_dlkm
BOARD_QTI_DYNAMIC_PARTITIONS_SIZE ?= 9122611200 # (BOARD_SUPER_PARTITION_SIZE - 4MB overhead)

$(foreach p, $(call to-upper, $(BOARD_QTI_DYNAMIC_PARTITIONS_PARTITION_LIST)), \
    $(if $(filter user,$(TARGET_BUILD_VARIANT)), \
        $(eval BOARD_$(p)IMAGE_FILE_SYSTEM_TYPE := erofs), \
        $(eval BOARD_$(p)IMAGE_FILE_SYSTEM_TYPE := ext4) \
        $(eval BOARD_$(p)IMAGE_PARTITION_RESERVED_SIZE := 104857600) \
    ) \
    $(eval TARGET_COPY_OUT_$(p) := $(call to-lower, $(p))) \
)

# Power
TARGET_POWER_FEATURE_EXT_LIB := //$(COMMON_PATH):libpowerfeature_ext_xiaomi

# Recovery
BOARD_EXCLUDE_KERNEL_FROM_RECOVERY_IMAGE := true
BOARD_USES_FULL_RECOVERY_IMAGE := true
TARGET_RECOVERY_FSTAB := $(COMMON_PATH)/rootdir/etc/fstab.qcom
TARGET_RECOVERY_PIXEL_FORMAT := RGBX_8888
TARGET_RECOVERY_UI_MARGIN_HEIGHT := 104
TARGET_USERIMAGES_USE_F2FS := true

# QTI vendor AIDs / file capabilities (imported from the known-good marble tree)
TARGET_FS_CONFIG_GEN := $(COMMON_PATH)/configs/config.fs

SOONG_CONFIG_NAMESPACES += ufsbsg
SOONG_CONFIG_ufsbsg += ufsframework
SOONG_CONFIG_ufsbsg_ufsframework := bsg

# QTI display gralloc handle layout (mirrors hardware/qcom-caf/common/BoardConfigQcom.mk;
# that file is not included by this tree).  UM 5.10 / GKI 2.0 targets use the
# full QTI gralloc struct.
TARGET_GRALLOC_HANDLE_HAS_CUSTOM_CONTENT_MD_RESERVED_SIZE ?= true
TARGET_GRALLOC_HANDLE_HAS_RESERVED_SIZE ?= true
TARGET_GRALLOC_HANDLE_HAS_UBWCP_FORMAT ?= false

$(call soong_config_set,qtidisplay,gralloc_handle_has_custom_content_md_reserved_size,$(TARGET_GRALLOC_HANDLE_HAS_CUSTOM_CONTENT_MD_RESERVED_SIZE))
$(call soong_config_set,qtidisplay,gralloc_handle_has_reserved_size,$(TARGET_GRALLOC_HANDLE_HAS_RESERVED_SIZE))
$(call soong_config_set,qtidisplay,gralloc_handle_has_ubwcp_format,$(TARGET_GRALLOC_HANDLE_HAS_UBWCP_FORMAT))

# UM 5.10 still uses the old rmnet data API (see BoardConfigQcom.mk)
$(call soong_config_set,rmnetctl,old_rmnet_data,true)

# Security patch level
VENDOR_SECURITY_PATCH := $(PLATFORM_SECURITY_PATCH)

# AOSPA display board config (GRALLOC4, HWC2, DRM PP, etc.)
-include hardware/qcom/display/config/display-board.mk

# Sepolicy
# AOSPA calcite policy (fork): path patched to device/qcom/sepolicy_vndr-aospa,
# and the is-vendor-board-platform guard removed (macro absent in PixelOS-CLO).
include device/qcom/sepolicy_vndr-aospa/SEPolicy.mk

# AOSPA device/qcom/common sepolicy (only the policy files; Soong side is pruned
# in custom_marble.mk). common/public is absent upstream, so add it conditionally.
COMMON_SEPOLICY_PATH := device/qcom/common/sepolicy
BOARD_VENDOR_SEPOLICY_DIRS += \
    $(COMMON_SEPOLICY_PATH)/generic/vendor/common \
    $(COMMON_SEPOLICY_PATH)/qva/vendor/common \
    $(COMMON_SEPOLICY_PATH)/generic/vendor/taro \
    $(COMMON_SEPOLICY_PATH)/qva/vendor/taro
ifneq (,$(filter userdebug eng, $(TARGET_BUILD_VARIANT)))
SYSTEM_EXT_PUBLIC_SEPOLICY_DIRS += $(COMMON_SEPOLICY_PATH)/qva/vendor/test
endif
# 注意：device/qcom/common/sepolicy/common/private 与 Lineage 的
# device/lineage/sepolicy/common/private 重复定义 vendor.camera.aux.packageexcludelist，
# 会触发 host_init_verifier duplicate prefix。这里只取 vendor 侧策略，
# system_ext 的 common/private、common/public 不加入。

BOARD_VENDOR_SEPOLICY_DIRS += $(COMMON_PATH)/sepolicy/vendor
SYSTEM_EXT_PRIVATE_SEPOLICY_DIRS += $(COMMON_PATH)/sepolicy/private

# Verified Boot
BOARD_AVB_ENABLE := true
BOARD_AVB_MAKE_VBMETA_IMAGE_ARGS += --flags 3

BOARD_AVB_RECOVERY_ALGORITHM := SHA256_RSA4096
BOARD_AVB_RECOVERY_KEY_PATH := external/avb/test/data/testkey_rsa4096.pem
BOARD_AVB_RECOVERY_ROLLBACK_INDEX := $(PLATFORM_SECURITY_PATCH_TIMESTAMP)
BOARD_AVB_RECOVERY_ROLLBACK_INDEX_LOCATION := 1

BOARD_AVB_VBMETA_SYSTEM := system system_ext product
BOARD_AVB_VBMETA_SYSTEM_ALGORITHM := SHA256_RSA2048
BOARD_AVB_VBMETA_SYSTEM_KEY_PATH := external/avb/test/data/testkey_rsa2048.pem
BOARD_AVB_VBMETA_SYSTEM_ROLLBACK_INDEX := $(PLATFORM_SECURITY_PATCH_TIMESTAMP)
BOARD_AVB_VBMETA_SYSTEM_ROLLBACK_INDEX_LOCATION := 2

# Vendor API
BOARD_SHIPPING_API_LEVEL := 31

# Wi-Fi
CONFIG_ACS := true
