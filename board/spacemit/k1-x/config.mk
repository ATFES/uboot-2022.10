# SPDX-License-Identifier: GPL-2.0+
#
# Copyright (c) 2022-2024 Spacemit, Inc


# Add 4KB header for u-boot-spl.bin
quiet_cmd_build_spl_platform = BUILD   $2
cmd_build_spl_platform = \
	cp $(objtree)/$3 \
		$(srctree)/board/$(CONFIG_SYS_VENDOR)/$(CONFIG_SYS_BOARD)/ && \
	python3 $(srctree)/tools/build_binary_file.py \
		-c $(srctree)/board/$(CONFIG_SYS_VENDOR)/$(CONFIG_SYS_BOARD)/configs/fsbl.json \
		-o $(objtree)/FSBL.bin; \
	python3 $(srctree)/tools/build_binary_file.py \
		-c $(srctree)/board/$(CONFIG_SYS_VENDOR)/$(CONFIG_SYS_BOARD)/configs/bootinfo_spinor.json \
		-o $(objtree)/bootinfo_spinor.bin; \
	python3 $(srctree)/tools/build_binary_file.py \
		-c $(srctree)/board/$(CONFIG_SYS_VENDOR)/$(CONFIG_SYS_BOARD)/configs/bootinfo_spinand.json \
		-o $(objtree)/bootinfo_spinand.bin; \
	python3 $(srctree)/tools/build_binary_file.py \
		-c $(srctree)/board/$(CONFIG_SYS_VENDOR)/$(CONFIG_SYS_BOARD)/configs/bootinfo_emmc.json \
		-o $(objtree)/bootinfo_emmc.bin; \
	python3 $(srctree)/tools/build_binary_file.py \
		-c $(srctree)/board/$(CONFIG_SYS_VENDOR)/$(CONFIG_SYS_BOARD)/configs/bootinfo_sd.json \
		-o $(objtree)/bootinfo_sd.bin && \
	rm -f $(srctree)/board/$(CONFIG_SYS_VENDOR)/$(CONFIG_SYS_BOARD)/u-boot-spl.bin

quiet_cmd_build_itb = BUILD   $2
cmd_build_itb = \
	mkdir -p $(srctree)/board/$(CONFIG_SYS_VENDOR)/$(CONFIG_SYS_BOARD)/dtb && \
	cp $(objtree)/arch/$(ARCH)/dts/*.dtb \
		$(srctree)/board/$(CONFIG_SYS_VENDOR)/$(CONFIG_SYS_BOARD)/dtb/ && \
	cp $(objtree)/u-boot-nodtb.bin \
		$(srctree)/board/$(CONFIG_SYS_VENDOR)/$(CONFIG_SYS_BOARD)/ && \
	$(objtree)/tools/mkimage -f \
		$(srctree)/board/$(CONFIG_SYS_VENDOR)/$(CONFIG_SYS_BOARD)/configs/uboot_fdt.its \
		-r $(objtree)/$2;\
	rm -rf $(srctree)/board/$(CONFIG_SYS_VENDOR)/$(CONFIG_SYS_BOARD)/dtb && \
	rm -f $(srctree)/board/$(CONFIG_SYS_VENDOR)/$(CONFIG_SYS_BOARD)/u-boot-nodtb.bin

quiet_cmd_build_default_env = BUILD   $2
cmd_build_default_env = \
	$(srctree)/scripts/get_default_envs.sh $(objtree) > $(objtree)/u-boot-env-default.txt && \
	$(objtree)/tools/mkenvimage -s $(CONFIG_ENV_SIZE) -o $(objtree)/u-boot-env-default.bin \
		$(objtree)/u-boot-env-default.txt

MRPROPER_FILES += $(srctree)/board/$(CONFIG_SYS_VENDOR)/$(CONFIG_SYS_BOARD)/u-boot-nodtb.bin
MRPROPER_FILES += $(srctree)/board/$(CONFIG_SYS_VENDOR)/$(CONFIG_SYS_BOARD)/u-boot-spl.bin
MRPROPER_FILES += u-boot.itb FSBL.bin u-boot-env-default.*
MRPROPER_FILES += bootinfo_spinor.bin bootinfo_spinand.bin bootinfo_emmc.bin bootinfo_sd.bin
MRPROPER_FILES += k1-x_evb.dtb k1-x_deb2.dtb k1-x_deb1.dtb k1-x_spl.dtb
MRPROPER_DIRS += $(srctree)/board/$(CONFIG_SYS_VENDOR)/$(CONFIG_SYS_BOARD)/dtb

u-boot.itb: u-boot-nodtb.bin u-boot-dtb.bin u-boot.dtb FORCE
	$(call if_changed,build_itb,$@)

ifneq ($(CONFIG_SPL_BUILD),)
INPUTS-y += FSBL.bin

FSBL.bin: spl/u-boot-spl.bin FORCE
	$(call if_changed,build_spl_platform,$@,$<)
else
INPUTS-y += u-boot-env-default.bin
u-boot-env-default.bin: u-boot-nodtb.bin FORCE
	$(call if_changed,build_default_env,$@)
endif
