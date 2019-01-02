# ---------------------------------------------------------------------
# ABS bootstrap make file.
# (c) 2006-2019 Sebastien Devaux
# (c) 2017-2019 ArianeGroup 
#
# To use ABS to build your project, just copy this file as 'Makefile' into
# your project's root directory and each already existing module directories.
# As soon your project's layout is complient to the ABS layout and contains
# the expected configuration files (app.cfg at top level, and module.cfg in 
# each module directory), you can invoke make command to build it.
# ---------------------------------------------------------------------
# Prerequisites: a quite regular shell including GNU make, tar, wget and
# few other widely available commands.
# Any GNU environment (GNU/Linux, cygwin, mingw, may be GNU/hurd) should
# be able to run this makefile.
# ---------------------------------------------------------------------
# See ABS documentation (ref #5b53baa) for more details.
# https://www.eduvax.net/gitweb
# ---------------------------------------------------------------------

ifneq ($(wildcard app.cfg),)
PRJROOT:=$(CURDIR)
endif
ifneq ($(wildcard module.cfg),)
PRJROOT:=$(shell dirname $(CURDIR))
endif
ABS_CACHE:=$(PRJROOT)/../abs-cache

include $(PRJROOT)/app.cfg
include $(PRJROOT)/.abs/core/main.mk

ABS_PRINT_info?=echo

$(ABS_CACHE)/%:
	@mkdir -p $(@D)
ifeq ($(findstring file://,$(ABS_REPO)),file://)
	@$(ABS_PRINT_info) "linking $(@F) from $(ABS_REPO)"
	@ln -sf $(patsubst file://%,%,$(patsubst $(ABS_CACHE)/%,$(ABS_REPO)/%,$@)) $@
else
	@$(ABS_PRINT_info) "fetching $(@F) from $(ABS_REPO)"
	@wget -q -no-cehck-certificate $(patsubst $(ABS_CACHE)/%,$(ABS_REPO)/%,$@) -O $@
endif

$(PRJROOT)/.abs/%/main.mk: $(ABS_CACHE)/noarch/abs.%-$(VABS).tar.gz
	@mkdir -p .abs
	@tar xzf $^ -C $(PRJROOT)/.abs --strip-components=1
	@touch $@
