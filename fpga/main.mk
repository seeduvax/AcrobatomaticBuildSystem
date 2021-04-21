FPGA_EXT_PATH:=$(dir $(lastword $(MAKEFILE_LIST)))

ifeq ($(BOARD),de10nano)
include $(FPGA_EXT_PATH)/de10nano/main.mk
include $(FPGA_EXT_PATH)/quartus.mk
endif
