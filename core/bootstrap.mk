# ---------------------------------------------------------------------
# AcrobatomaticBuildSystem bootstrap make file.
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
# See ABS documentation (ref #170983b) for more details.
# https://www.eduvax.net/gitweb
# https://github.com/seeduvax/AcrobatomaticBuildSystem
# ---------------------------------------------------------------------

ifneq ($(wildcard app.cfg),)
PRJROOT:=$(CURDIR)
endif
ifneq ($(wildcard module.cfg),)
PRJROOT:=$(dir $(CURDIR))
endif
ifeq ($(HOME),)
ABSWS:=$(PRJROOT)/../abs
else
ABSWS:=$(HOME)/.abs
endif

include $(PRJROOT)/app.cfg
-include $(ABSWS)/local.cfg
-include $(PRJROOT)/local.cfg
ifneq ($(wildcard module.cfg),)
-include $(CURDIR)/local.cfg
endif
ABSROOT:=$(ABSWS)/abs-$(VABS)
ABS_CACHE:=$(ABSWS)/cache
include $(ABSROOT)/core/main.mk

# Default and minimal rule download files from repository
# May be overloaded by dependencies download rules for more features
ifeq ($(ABS_DEPDOWNLOAD_RULE_OVERLOADED),)
ABS_REPO_1ST=$(word 1,$(ABS_REPO))
ifeq ($(findstring %,$(ABS_REPO_1ST)),)
ABS_REPO_PATTERN_1ST:=$(ABS_REPO_1ST)/$(ARCH)/%
ABS_REPO_NA_PATTERN_1ST:=$(ABS_REPO_1ST)/noarch/%
else
$(eval ABS_REPO_PATTERN_1ST:=$(ABS_REPO_1ST))
$(eval ABS_REPO_NA_PATTERN_1ST:=$(subst $$(ARCH),noarch,$(ABS_REPO_1ST)))
endif

$(ABS_CACHE)/noarch/%:
	@mkdir -p $(@D)
ifeq ($(findstring file://,$(ABS_REPO_NA_PATTERN_1ST)),file://)
	test -r $(patsubst file://%,%,$(patsubst %,$(ABS_REPO_NA_PATTERN_1ST),$(@F))) || exit 1
	echo "Linking $(@F) from $(ABS_REPO_NA_PATTERN_1ST)"
	ln -sf $(patsubst file://%,%,$(patsubst /%,$(ABS_REPO_NA_PATTERN_1ST)/%,$(@F))) $@
else
	echo "Fetching $(@F) from $(ABS_REPO_NA_PATTERN_1ST)"
	wget -q $(WGETFLAGS) $(patsubst %,$(ABS_REPO_NA_PATTERN_1ST)/%,$(@F)) -O $@
endif

$(ABS_CACHE)/%:
	@mkdir -p $(@D)
ifeq ($(findstring file://,$(ABS_REPO_PATTERN_1ST)),file://)
	@test -r $(patsubst file://%,%,$(patsubst %,$(ABS_REPO_PATTERN_1ST),$(@F))) || exit 1
	@echo "Linking $(@F) from $(ABS_REPO_PATTERN_1ST)"
	@ln -sf $(patsubst file://%,%,$(patsubst /%,$(ABS_REPO_PATTERN_1ST)/%,$(@F))) $@
else
	@echo "Fetching $(@F) from $(ABS_REPO_PATTERN_1ST)"
	@wget -q $(WGETFLAGS) $(patsubst %,$(ABS_REPO_PATTERN_1ST)/%,$(@F)) -O $@
endif

endif

$(ABSROOT)/%/main.mk: $(ABS_CACHE)/noarch/abs.%-$(VABS).tar.gz
	@mkdir -p $(ABSROOT)
	@tar xzf $^ -C $(ABSROOT) --strip-components=1
	@touch $@

$(PRJROOT)/local.cfg:
	@:
