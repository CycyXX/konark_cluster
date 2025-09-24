# Copyright 2025 ETH Zurich and University of Bologna.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0
#
# Author: Cyrill Durrer <cdurrer@iis.ee.ethz.ch>

KC_ROOT ?= $(shell pwd)
# KC_GEN_DIR = $(KC_ROOT)/.generated
BENDER_ROOT ?= $(KC_ROOT)/.bender

# Executables
BENDER        ?= bender -d $(KC_ROOT)
VERIBLE_FMT      ?= verible-verilog-format
VERIBLE_FMT_ARGS ?= --flagfile .verilog_format --inplace --verbose
PEAKRDL          ?= peakrdl

# Include snitch cluster
# SN_CFG	  ?= $(KC_ROOT)/cfg/konark_cluster.json
SN_ROOT   = $(shell $(BENDER) path snitch_cluster)
# SN_GEN_DIR = $(KC_GEN_DIR)
include $(SN_ROOT)/make/common.mk
include $(SN_ROOT)/make/rtl.mk


# Bender prerequisites
BENDER_YML = $(KC_ROOT)/Bender.yml
BENDER_LOCK = $(KC_ROOT)/Bender.lock

################
# Bender flags #
################

COMMON_TARGS += -t rtl -t snitch_cluster -t kc_gen_rtl
# COMMON_TARGS += -t rtl -t cva6 -t cv64a6_imafdcsclic_sv39 -t snitch_cluster -t pb_gen_rtl
# SIM_TARGS += -t simulation -t test -t idma_test

#############
# systemRDL #
#############

# KC_RDL_ALL += $(KC_GEN_DIR)/konark_cluster.rdl
# KC_RDL_ALL += $(KC_GEN_DIR)/snitch_cluster.rdl
# KC_RDL_ALL += $(wildcard $(KC_ROOT)/cfg/rdl/*.rdl)

# PEAKRDL_INCLUDES += -I $(KC_ROOT)/cfg/rdl
# PEAKRDL_INCLUDES += -I $(SN_ROOT)/hw/snitch_cluster/src/snitch_cluster_peripheral
# PEAKRDL_INCLUDES += -I $(KC_GEN_DIR)

# $(KC_GEN_DIR)/pb_soc_regs.sv: $(KC_GEN_DIR)/pb_soc_regs_pkg.sv
# $(KC_GEN_DIR)/pb_soc_regs_pkg.sv: $(KC_ROOT)/cfg/rdl/pb_soc_regs.rdl
# 	$(PEAKRDL) regblock $< -o $(KC_GEN_DIR) --cpuif apb4-flat --default-reset arst_n -P Num_Clusters=$(SN_CLUSTERS) -P Num_Mem_Tiles=$(L2_TILES)

# $(KC_GEN_DIR)/picobello.rdl: $(FLOO_CFG)
# 	$(FLOO_GEN) -c $(FLOO_CFG) -o $(KC_GEN_DIR) --rdl --rdl-as-mem --rdl-memwidth=32

# # Those are dummy RDL files, for generation without access to the PD repository.
# $(KC_GEN_DIR)/fll.rdl $(KC_GEN_DIR)/pb_chip_regs.rdl:
# 	@touch $@

# $(KC_GEN_DIR)/pb_addrmap.h: $(KC_GEN_DIR)/picobello.rdl $(KC_RDL_ALL)
# 	$(PEAKRDL) c-header $< $(PEAKRDL_INCLUDES) $(PEAKRDL_DEFINES) -o $@ -i -b ltoh

# $(KC_GEN_DIR)/pb_addrmap.svh: $(KC_RDL_ALL)
# 	$(PEAKRDL) raw-header $< -o $@ $(PEAKRDL_INCLUDES) $(PEAKRDL_DEFINES) --format svh

# KC_RDL_HW_ALL += $(KC_GEN_DIR)/pb_soc_regs.sv
# KC_RDL_HW_ALL += $(KC_GEN_DIR)/pb_soc_regs_pkg.sv
# KC_RDL_HW_ALL += $(KC_GEN_DIR)/pb_addrmap.svh

# .PHONY: pb-soc-regs pb-soc-regs-clean
# pb-soc-regs: $(KC_GEN_DIR)/pb_soc_regs.sv $(KC_GEN_DIR)/pb_soc_regs_pkg.sv

# pb-soc-regs-clean:
# 	rm -rf $(KC_GEN_DIR)/pb_soc_regs.sv $(KC_GEN_DIR)/pb_soc_regs_pkg.sv

# .PHONY: pb-addrmap
# pb-addrmap: $(KC_GEN_DIR)/pb_addrmap.h $(KC_GEN_DIR)/pb_addrmap.svh


##################
# Snitch Cluster #
##################

TARGET = konark_cluster

SN_BENDER = $(BENDER)

SN_BOOTDATA_TPL = $(SN_ROOT)/hw/snitch_cluster/test/bootdata.cc.tpl
$(eval $(call sn_cluster_gen_rule,$(SN_GEN_DIR)/bootdata.cc,$(SN_BOOTDATA_TPL)))

SN_TB_CC_SOURCES += \
	$(SN_TB_DIR)/ipc.cc \
	$(SN_TB_DIR)/common_lib.cc \
	$(SN_GEN_DIR)/bootdata.cc

SN_RTL_CC_SOURCES += $(SN_TB_DIR)/rtl_lib.cc

SN_VLT_CC_SOURCES += \
	$(SN_TB_DIR)/verilator_lib.cc \
	$(SN_TB_DIR)/tb_bin.cc

SN_TB_CC_FLAGS += \
	-std=c++14 \
	-I$(SN_FESVR)/include \
	-I$(SN_TB_DIR)

SN_FESVR = $(SN_WORK_DIR)
SN_FESVR_VERSION ?= 35d50bc40e59ea1d5566fbd3d9226023821b1bb6

# Eventually it could be an option to package this statically using musl libc.
$(SN_WORK_DIR)/$(SN_FESVR_VERSION)_unzip: | $(SN_WORK_DIR)
	wget -O $(dir $@)/$(SN_FESVR_VERSION) https://github.com/riscv/riscv-isa-sim/tarball/$(SN_FESVR_VERSION)
	tar xfm $(dir $@)$(SN_FESVR_VERSION) --strip-components=1 -C $(dir $@)
	touch $@

$(SN_WORK_DIR)/lib/libfesvr.a: $(SN_WORK_DIR)/$(SN_FESVR_VERSION)_unzip
	cd $(dir $<)/ && ./configure --prefix `pwd`
	make -C $(dir $<) install-config-hdrs install-hdrs libfesvr.a
	mkdir -p $(dir $@)
	cp $(dir $<)libfesvr.a $@

SN_VERILATOR_SEPP=oseda
# SN_VSIM_BUILDDIR = $(KC_ROOT)/target/sim/build/work-vsim
include $(SN_ROOT)/make/vsim.mk

# include $(SN_ROOT)/make/common.mk
# include $(SN_ROOT)/make/rtl.mk

# .PHONY: sn-hw-clean sn-hw-all

# sn-hw-all: $(SN_CLUSTER_WRAPPER) $(SN_CLUSTER_PKG)
# sn-hw-clean:
# 	rm -rf $(SN_CLUSTER_WRAPPER) $(SN_CLUSTER_PKG)

#########################
# General Phony targets #
#########################

KC_HW_ALL += $(KC_RDL_HW_ALL)

.PHONY: konark_cluster-hw-all konark_cluster-hw-clean clean

konark_cluster-hw-all all: $(KC_HW_ALL) sn-rtl
	$(MAKE) $(KC_HW_ALL)

konark_cluster-hw-clean clean: sn-clean-rtl
	rm -rf $(BENDER_ROOT)

############
# Software #
############

include $(SN_ROOT)/make/sw.mk
# include $(KC_ROOT)/sw/sw.mk

##############
# Simulation #
##############

TB_DUT = testharness_konark_cluster

# include $(KC_ROOT)/target/sim/vsim/vsim.mk
# include $(KC_ROOT)/target/sim/traces.mk

##################
# Snitch cluster #
##################

# $(call sn_include_deps)

########
# Misc #
########

BASE_PYTHON ?= python
PIP_CACHE_DIR ?= $(KC_ROOT)/.cache/pip

.PHONY: dvt-flist python-venv python-venv-clean verible-fmt

dvt-flist:
	$(BENDER) script flist-plus $(COMMON_TARGS) $(SIM_TARGS) > .dvt/default.build

python-venv: .venv
.venv:
	$(BASE_PYTHON) -m venv $@
	. $@/bin/activate && \
	python -m pip install --upgrade pip setuptools && \
	python -m pip install --cache-dir $(PIP_CACHE_DIR) -r requirements.txt && \
	python -m pip install $(shell $(BENDER) path snitch_cluster)
# ToDo(cdurrer): not tested

python-venv-clean:
	rm -rf .venv

verible-fmt:
	$(VERIBLE_FMT) $(VERIBLE_FMT_ARGS) $(shell $(BENDER) script flist $(SIM_TARGS) --no-deps)

#################
# Documentation #
#################

.PHONY: help

Black=\033[0m
Green=\033[1;32m
help:
	@echo -e "Konark Cluster help"
	@echo -e "Makefile ${Green}targets${Black} for konark_cluster"
	@echo -e "Use 'make <target>' where <target> is one of:"
	@echo -e ""
	@echo -e "${Green}help           	     ${Black}Show an overview of all Makefile targets."
	@echo -e ""
	@echo -e "General targets:"
# 	@echo -e "${Green}all                  ${Black}Alias for konark_cluster-hw-all."
# 	@echo -e "${Green}clean                ${Black}Alias for konark_cluster-hw-clean."
	@echo -e ""
	@echo -e "Source generation targets:"
# 	@echo -e "${Green}konark_cluster-hw-all     ${Black}Build all RTL."
# 	@echo -e "${Green}konark_cluster-hw-clean   ${Black}Clean everything."
	@echo -e "${Green}sn-rtl               ${Black}Generate Snitch Cluster wrapper RTL."
	@echo -e "${Green}sn-clean-rtl         ${Black}Clean Snitch Cluster wrapper RTL."
	@echo -e ""
	@echo -e "Software:"
# 	@echo -e "${Green}sw                   ${Black}Compile all software tests."
# 	@echo -e "${Green}sw-clean             ${Black}Clean all software tests."
	@echo -e "${Green}sn-sw                ${Black}Compile Snitch software: runtime, tests and apps."
	@echo -e "${Green}sn-clean-sw          ${Black}Clean Snitch software: runtime, tests and apps."
	@echo -e "${Green}sn-tests             ${Black}Compile Snitch software tests."
	@echo -e "${Green}sn-clean-tests       ${Black}Clean Snitch software tests."
	@echo -e ""
	@echo -e "Simulation targets:"
# 	@echo -e "${Green}vsim-compile         ${Black}Compile with Questasim."
# 	@echo -e "${Green}vsim-run             ${Black}Run QuestaSim simulation in GUI mode w/o optimization."
# 	@echo -e "${Green}vsim-run-batch       ${Black}Run QuestaSim simulation in batch mode w/ optimization."
# 	@echo -e "${Green}vsim-clean           ${Black}Clean QuestaSim simulation files."
	@echo -e ""
	@echo -e "Additional miscellaneous targets:"
# 	@echo -e "${Green}traces               ${Black}Generate the better readable traces in .logs/trace_hart_<hart_id>.txt."
# 	@echo -e "${Green}annotate             ${Black}Annotate the better readable traces in .logs/trace_hart_<hart_id>.s with the source code related with the retired instructions."
# 	@echo -e "${Green}dvt-flist            ${Black}Generate a file list for the VSCode DVT plugin."
	@echo -e "${Green}python-venv          ${Black}Create a Python virtual environment and install the required packages."
	@echo -e "${Green}python-venv-clean    ${Black}Remove the Python virtual environment."
	@echo -e "${Green}verible-fmt          ${Black}Format SystemVerilog files using Verible."


# 	@echo -e "Makefile ${Green}targets${Black} for picobello"
# 	@echo -e "Use 'make <target>' where <target> is one of:"
# 	@echo -e ""
# 	@echo -e "${Green}help           	     ${Black}Show an overview of all Makefile targets."
# 	@echo -e ""
# 	@echo -e "General targets:"
# 	@echo -e "${Green}all                  ${Black}Alias for picobello-hw-all."
# 	@echo -e "${Green}clean                ${Black}Alias for picobello-hw-clean."
# 	@echo -e ""
# 	@echo -e "Source generation targets:"
# 	@echo -e "${Green}picobello-hw-all     ${Black}Build all RTL."
# 	@echo -e "${Green}picobello-hw-clean   ${Black}Clean everything."
# 	@echo -e "${Green}floo-hw-all          ${Black}Generate FlooNoC RTL."
# 	@echo -e "${Green}floo-clean           ${Black}Clean FlooNoC RTL."
# 	@echo -e "${Green}sn-hw-all            ${Black}Generate Snitch Cluster wrapper RTL."
# 	@echo -e "${Green}sn-hw-clean          ${Black}Clean Snitch Cluster wrapper RTL."
# 	@echo -e "${Green}chs-hw-all           ${Black}Generate Cheshire RTL."
# 	@echo -e ""
# 	@echo -e "Software:"
# 	@echo -e "${Green}sw                   ${Black}Compile all software tests."
# 	@echo -e "${Green}sw-clean             ${Black}Clean all software tests."
# 	@echo -e "${Green}chs-sw-tests         ${Black}Compile Cheshire software tests."
# 	@echo -e "${Green}chs-sw-tests-clean   ${Black}Clean Cheshire software tests."
# 	@echo -e "${Green}sn-tests             ${Black}Compile Snitch software tests."
# 	@echo -e "${Green}sn-clean-tests       ${Black}Clean Snitch software tests."
# 	@echo -e ""
# 	@echo -e "Simulation targets:"
# 	@echo -e "${Green}vsim-compile         ${Black}Compile with Questasim."
# 	@echo -e "${Green}vsim-run             ${Black}Run QuestaSim simulation in GUI mode w/o optimization."
# 	@echo -e "${Green}vsim-run-batch       ${Black}Run QuestaSim simulation in batch mode w/ optimization."
# 	@echo -e "${Green}vsim-clean           ${Black}Clean QuestaSim simulation files."
# 	@echo -e ""
# 	@echo -e "Additional miscellaneous targets:"
# 	@echo -e "${Green}traces               ${Black}Generate the better readable traces in .logs/trace_hart_<hart_id>.txt."
# 	@echo -e "${Green}annotate             ${Black}Annotate the better readable traces in .logs/trace_hart_<hart_id>.s with the source code related with the retired instructions."
# 	@echo -e "${Green}dvt-flist            ${Black}Generate a file list for the VSCode DVT plugin."
# 	@echo -e "${Green}python-venv          ${Black}Create a Python virtual environment and install the required packages."
# 	@echo -e "${Green}python-venv-clean    ${Black}Remove the Python virtual environment."
# 	@echo -e "${Green}verible-fmt          ${Black}Format SystemVerilog files using Verible."
