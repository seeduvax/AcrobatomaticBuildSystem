## 
## --------------------------------------------------------------------
## Global overloadable variables:
## --------------------------------------------------------------------
##  - MODE: compilation mode
##          debug (default): with debug symbols, without compiler
##                           optimizations
##          release: without debug symbols, with some compiler
##                           optimizations
##  - ABS_LOG_LEVEL: Logs minimal level
##          debug: all logs are shown
##          info (default): only logs from info level are shown.
MODE?=debug
ABSROOT?=$(ABSWS)/abs-$(VABS)
# to avoid ancient sh behaviour on debian
SHELL=/bin/bash

# ------------------------------------------------------
# macro for pretty message print, use color if available
COLORS_TCAP:=$(shell ncolors=`tput colors 2>/dev/null` ; ( [ "$$ncolors" != "" ] && [ "$$ncolors" -ge 0 ] ) && echo yes || echo no)

ABS_LOG_LEVEL?=info
ifeq ($(COLORS_TCAP),yes)
ABS_COLOR_DEBUG:=\e[36m
ABS_COLOR_INFO:=\e[39;1m
ABS_COLOR_WARNING:=\e[35;1m
ABS_COLOR_ERROR:=\e[31;1m
ABS_COLOR_HILIGHT:=\e[34;1m
ABS_COLOR_RESTORE:=\e[0m
else
ABS_COLOR_DEBUG:=
ABS_COLOR_INFO:=
ABS_COLOR_WARNING:=
ABS_COLOR_ERROR:=
ABS_COLOR_HILIGHT:=
ABS_COLOR_RESTORE:=
endif

ABS_PRINT_DEBUG_CMD:=env printf
ABS_PRINT_INFO_CMD:=env printf
ABS_PRINT_WARNING_CMD:=env printf
ABS_PRINT_ERROR_CMD:=env printf
ABS_PRINT_CMD:=env printf
ifneq ($(ABS_LOG_LEVEL),debug)
ABS_PRINT_DEBUG_CMD:=:
ifneq ($(ABS_LOG_LEVEL),info)
ABS_PRINT_INFO_CMD:=:
endif
endif
ABS_PRINT_debug:=$(ABS_PRINT_DEBUG_CMD) "$(ABS_COLOR_DEBUG)[abs-debug]\t%s$(ABS_COLOR_RESTORE)\n"
ABS_PRINT_info:=$(ABS_PRINT_INFO_CMD) "$(ABS_COLOR_INFO)[abs-info]\t%s$(ABS_COLOR_RESTORE)\n"
ABS_PRINT_warning:=$(ABS_PRINT_WARNING_CMD) "$(ABS_COLOR_WARNING)[abs-warning]\t%s$(ABS_COLOR_RESTORE)\n"
ABS_PRINT_error:=$(ABS_PRINT_ERROR_CMD) "$(ABS_COLOR_ERROR)[abs-error]\t%s$(ABS_COLOR_RESTORE)\n"
ABS_PRINT:=$(ABS_PRINT_CMD) "$(ABS_COLOR_HILIGHT)[[abs-%s]]\t%s$(ABS_COLOR_RESTORE)\n"
export ABS_PRINT_debug
export ABS_PRINT_info
export ABS_PRINT_warning
export ABS_PRINT_error
export ABS_PRINT
ifeq ($(ABS_PRINT_DEBUG_CMD),:)
define abs_debug
endef
else
define abs_debug
$(info $(shell $(ABS_PRINT_DEBUG_CMD) "$(ABS_COLOR_DEBUG)[abs-info]\t$1$(ABS_COLOR_RESTORE)"))
endef
endif
ifeq ($(ABS_PRINT_INFO_CMD),:)
define abs_info
endef
else
define abs_info
$(info $(shell $(ABS_PRINT_INFO_CMD) "$(ABS_COLOR_INFO)[abs-info]\t$1$(ABS_COLOR_RESTORE)"))
endef
endif
define abs_warning
$(info $(shell $(ABS_PRINT_WARNING_CMD) "$(ABS_COLOR_WARNING)[abs-info]\t$1$(ABS_COLOR_RESTORE)"))
endef
define abs_error
$(info $(shell $(ABS_PRINT_ERROR_CMD) "$(ABS_COLOR_ERROR)[abs-info]\t$1$(ABS_COLOR_RESTORE)"))
endef

# -----------------------------------------------------
# Misc utility macros
define find
$(foreach d,$(filter-out $1/..,$(filter-out $1/.,$(wildcard $1/* $1/.*))),$(if $(wildcard $d/.),$(call find,$d,$2),$(filter $(subst *,%,$2),$d)))
endef
define filter_substr
$(foreach w,$2,$(if $(findstring $1,$w),$w,))
endef
define filter_out_substr
$(foreach w,$2,$(if $(findstring $1,$w),,$w))
endef

define generateTmpVariable
$1$(shell echo $$RANDOM $$RANDOM $$RANDOM $$RANDOM | md5sum | head -c 8)
endef


TRACE_DATE_CMD:=date '+%Y-%m-%d %H:%M:%S%z'

# some vars to store some particular chars for their use in macros.
define _carriage_return_
!!
!!
endef
_carriage_return_:=$(patsubst !!,,$(_carriage_return_))
_space_=$(subst ,, )
_comma_=,

##  - ABS_REPO: dependencies repositories. URL pattern. Repositories shall
##       be listed according the expected search order. Use space char as
##       separator.
##       Pattern shall include % char for file name substitution.
##       Pattern may include any other variable, however ARCH variable
##       shall be someway escaped with double $ to be properly substitued
##       in any case.
##       Exemple:
##       ABS_REPO=file://usr/local/dist/$$(ARCH)/% https://example.org/abs/%?arch=$$(ARCH)

##  - USER: name of the user running the build
USER?=$(shell whoami)
USER:=$(subst \,/,$(USER))
# ISWINDOWS indicates ABS run on Windows (with cygwin or msys)
ISWINDOWS?=$(if $(WINDIR),true)
ifeq ($(ISWINDOWS),true)
define absGetPath
$(shell cygpath -m $(1))
endef
else
define absGetPath
$(1)
endef
endif
BUILDNUM=null

# ---------------------------------------------------------------------
# application and modules parameteres
# ---------------------------------------------------------------------
##  - BUILDROOT: build root directory
BUILDROOT?=$(PRJROOT)/build
HOSTNAME?=$(shell hostname)

ABS_SCM_TYPE:=null
DISTINFO_FILENAME=.distinfo.mk
MODDEPS_FILENAME=moddeps.mk

# explicitely checking and forcing variable makefile generation now since 
# include + rule may lead to delayed include, making this one to late regarding
# other includes to be done.
ifeq ($(wildcard $(BUILDROOT)/.abs/vars.mk),)
$(info $(shell $(ABS_PRINT_info) "Generating workspace variables files."))
_ABS_FAKE_VAR:=$(shell make -f $(ABSROOT)/core/genvars.mk BUILDROOT=$(BUILDROOT) HOSTNAME=$(HOSTNAME))
endif

include $(BUILDROOT)/.abs/vars.mk

ifeq ($(wildcard $(BUILDROOT)/.abs/$(HOSTNAME)-vars.mk),)
$(info $(shell $(ABS_PRINT_info) "Generating host variables files."))
_ABS_FAKE_VAR:=$(shell make -f $(ABSROOT)/core/genvars.mk BUILDROOT=$(BUILDROOT) HOSTNAME=$(HOSTNAME))
endif

include $(BUILDROOT)/.abs/$(HOSTNAME)-vars.mk

##  - ARCH: Architecture (ex: Debian_8_x86_64)
ARCH?=$(SYSNAME)_$(HWNAME)

ifeq ($(ISWINDOWS),true)
PATH_SEP:=;
else
PATH_SEP:=:
endif

VERSION_OVERLOADED:=$(filter VERSION=%,$(MAKEOVERRIDES))

VERSION_FIELDS:=$(subst ., ,$(VERSION))
VMAJOR:=$(word 1,$(VERSION_FIELDS))
VMEDIUM:=$(word 2,$(VERSION_FIELDS))
VMINOR:=$(word 3,$(VERSION_FIELDS))
VSUFFIX:=$(patsubst %,.%,$(word 4,$(VERSION_FIELDS)))

ifneq ($(DISABLE_SCM_CHECK),true)
include $(ABSROOT)/core/scm-$(ABS_SCM_TYPE).mk
endif

# if version is overloaded, consider workspace is tag.
ifneq ($(VERSION_OVERLOADED),)
WORKSPACE_IS_TAG:=1
endif

##  - TRDIR: target root directory (where the installed product image is stored)
TRDIR?=$(BUILDROOT)/$(ARCH)/$(MODE)

KVERSION?=$(shell uname -r)

# include application global parameters
# re-include in case that common variables are used in this cfg.
include $(PRJROOT)/app.cfg
ifneq ($(MODROOT),)
include $(MODROOT)/module.cfg
endif

-include $(ABSWS)/local.cfg
-include $(PRJROOT)/local.cfg

# process BUILDCHAIN after re-include because NDUSELIB can be resetted
ifneq ($(BUILDCHAIN),)
NDUSELIB+=$(BUILDCHAIN)
# replace | by - to support <lib>|<version>
VFLAVOR+=$(subst |,-,$(BUILDCHAIN))
endif

# identify dev version from tagged version, only when version is not overloaded.
ifeq ($(ABS_SCM_TYPE),null)
VERSION:=$(VERSION)e
endif
ifeq ($(WORKSPACE_IS_TAG),0)
VERSION:=$(VERSION)d
else
MODE=release
endif
ifneq ($(filter kdistinstall,$(MAKECMDGOALS)),)
MODE=release
endif

PRJOBJDIR=$(TRDIR)/obj
# directory for dist compilation
DIST_FLATTEN_DIR=$(PRJROOT)/dist/flatten
TR_DIST_DIR=$(DIST_FLATTEN_DIR)/$(APPNAME)-$(VERSION)

# log containing all commands executed to generate objects
BUILDLOG=$(PRJOBJDIR)/build.log

define writeToBuildLogs
mkdir -p $(PRJOBJDIR) && echo "`$(TRACE_DATE_CMD)`> $(if $(MODNAME),$(MODNAME): )$(subst ",\",$1)" >> $(BUILDLOG)
endef
define executeAndLogCmd
$(call writeToBuildLogs,$1); $1
endef

ifeq ($(MAKE_RESTARTS),)
ifeq ($(MAKELEVEL),0)
NOTHING:=$(shell test ! -f $(BUILDLOG) || rm -f $(BUILDLOG)))
endif
NOTHING:=$(shell $(call writeToBuildLogs,make goals: $(MAKECMDGOALS)))
endif

# external libraries local repository
INCTESTS:=$(filter test %test check %check testbuild help coverage Test%,$(MAKECMDGOALS))

# profiler.mk contains VFLAVOR
include $(ABSROOT)/core/profiler.mk

ifneq ($(VFLAVOR),)
VERSION:=$(VERSION)_$(subst $(_space_),_,$(sort $(VFLAVOR)))
endif

# BROWSER was introduced for charm but is not really needed yet...
#BROWSER:=$(word 1,$(shell which chromium firefox chrome edge safari iexplorer firefox-esr 2>/dev/null))
ifneq ($(wildcard $(PRJROOT)/_charm),)
include $(ABSROOT)/charm/main.mk
endif

ALL_PROJ_MODULES=$(patsubst $(PRJROOT)/%/module.cfg,%,$(wildcard $(PRJROOT)/*/module.cfg))
ALL_PROJ_MODDEPS_MK=$(patsubst %,$(PRJOBJDIR)/%/$(MODDEPS_FILENAME),$(ALL_PROJ_MODULES))
# PROJECT_INC_MODS permit to filter project modules in INCLUDE_MODS variable for example.
PROJECT_INC_MODS=$(patsubst %,$(APPNAME)_%,$(ALL_PROJ_MODULES))
LOAD_MODDEPS_FILE=$(PRJOBJDIR)/loadmoddeps.mk

# dependencies between modules
$(PRJOBJDIR)/%/$(MODDEPS_FILENAME): $(PRJROOT)/app.cfg $(PRJROOT)/%/module.cfg
	@+make -C $(PRJROOT)/$* --no-print-directory ABSROOT="$(ABSROOT)" TRDIR="$(TRDIR)" -f $(ABSROOT)/core/module-depends.mk generate

$(LOAD_MODDEPS_FILE): $(ALL_PROJ_MODDEPS_MK)
	@printf 'include $$(if $$(MODNAME),$$(PRJOBJDIR)/$$(MODNAME)/$(MODDEPS_FILENAME),$$(patsubst %%,$$(PRJOBJDIR)/%%/$(MODDEPS_FILENAME),$$(MODULES_DEPS)))' > $@

# include extern libraries management rules
ifneq ($(INCLUDE_EXTLIB),false)
include $(ABSROOT)/core/common-extlib.mk
endif

## 
## --------------------------------------------------------------------
## Common targets
## --------------------------------------------------------------------
##  - help: Show this help
help:
	@grep -h "^## " $(MAKEFILE_LIST) | sed -e 's/^## //' ; echo ; echo
