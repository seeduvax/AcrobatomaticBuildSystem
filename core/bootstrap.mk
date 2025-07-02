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
ABSWS?=$(PRJROOT)/../abs
else
ABSWS?=$(HOME)/.abs
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
OPEN_BRACE:={
ABS_REPO_TEMPLATE=$(foreach entry, $(ABS_REPO),$(if $(findstring $(OPEN_BRACE),$(entry)),$(entry),$(entry)/{arch}/{name}-{version}.{arch}.{ext} $(entry)/{arch}/{name}/{name}-{version}.{arch}.{ext} $(entry)/noarch/{name}-{version}.{ext}))
# CAUTION: empty line before endef into the next 3 macro define is needed
define GetFileWget
	@test -f $2 || ( echo "Downloading $1..." ; wget -q $(WGETFLAGS) $1 -O $2 || rm -f $2 )

endef
define GetFileScp
	@test -f $2 || ( echo "Downloading $1..." ; scp $(SCPFLAGS) $(patsubst scp:%,%,$1) $2 || : )

endef
define GetFileLink
	@test -f $2 || ( echo "Linking $1..." ; ln -sf $(patsubst file://%,%,$1) $2 ; test -r $2 || rm -f $2 )

endef
define downloadFromURLs
$(foreach entry,$2,$(if $(filter file://%,$(entry),),$(call GetFileLink,$(entry),$1))$(if $(filter scp:%,$(entry),),$(call GetFileScp,$(entry),$1))$(if $(filter-out file://% scp:%,$(entry)),$(call GetFileWget,$(entry),$1)))
endef

$(ABS_CACHE)/noarch/abs.%-$(VABS).tar.gz:
	@mkdir -p $(@D)
	$(call downloadFromURLs,$@,$(subst {name},abs.core,$(subst {version},$(VABS),$(subst {ext},tar.gz,$(subst {arch},noarch,$(ABS_REPO_TEMPLATE))))))
	@test -f $@

endif

$(ABSROOT)/%/main.mk: $(ABS_CACHE)/noarch/abs.%-$(VABS).tar.gz
	@mkdir -p $(ABSROOT)
	@tar -xmzf $< -C $(ABSROOT) --strip-components=1
	@touch $@
