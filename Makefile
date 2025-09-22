# Copyright 2024 ETH Zurich and University of Bologna.
# Solderpad Hardware License, Version 0.51, see LICENSE for details.
# SPDX-License-Identifier: SHL-0.51

# Determine the root of the snitch_cluster repository
SN_ROOT = $(shell bender path snitch_cluster)

# Set the generated RTL directory to our local generated folder
SN_GEN_DIR = $(PWD)/generated

# Include snitch_cluster's build system
include $(SN_ROOT)/make/common.mk
include $(SN_ROOT)/make/rtl.mk

# Default target
all: sn-rtl

# Clean target
clean: sn-clean-rtl
	rm -rf generated/

.PHONY: all clean