## 
## --------------------------------------------------------------------
## Global overloadable variables:
## --------------------------------------------------------------------
##  - MODE: compilation mode
##          debug (default): with debug symbols, without compiler 
##                           optimizations
##          release: without debug symbols, with some compiler
##                           optimizations
MODE?=debug
ABSROOT?=$(ABSWS)/abs-$(VABS)
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

##  - XARCH: defined alternate architecture for cross compilation. See
##     available files in $(ABSROOT)/core/xarch to get supported
##     architecture names (remove .mk suffix to get arch name)
ifneq ($(XARCH),)
include $(ABSROOT)/core/xarch/$(XARCH).mk
endif

##  - USER: name of the user running the build
USER?=$(shell whoami)
USER:=$(subst \,/,$(USER))
ISWINDOWS:=$(if $(WINDIR),true,)
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

ifeq ($(ARCH),)
##  - ARCH: Architecture (ex: Debian_8_x86_64)
ARCH:=$(SYSNAME)_$(HWNAME)
endif
ifeq ($(ISWINDOWS),true)
PATH_SEP:=;
else
PATH_SEP:=:
endif

##  - TRDIR: target root directory (where the installed product image is stored)
TRDIR?=$(BUILDROOT)/$(ARCH)/$(MODE)
VERSION_OVERLOADED:=$(filter VERSION=%,$(MAKEOVERRIDES))

VERSION_FIELDS:=$(subst ., ,$(VERSION))
VMAJOR:=$(word 1,$(VERSION_FIELDS))
VMEDIUM:=$(word 2,$(VERSION_FIELDS))
VMINOR:=$(word 3,$(VERSION_FIELDS))
VSUFFIX:=$(patsubst %,.%,$(word 4,$(VERSION_FIELDS)))

include $(ABSROOT)/core/scm-$(ABS_SCM_TYPE).mk

# if version is overloaded, consider workspace is tag.
ifneq ($(VERSION_OVERLOADED),)
WORKSPACE_IS_TAG:=1
endif

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
VFLAVOR+= $(BUILDCHAIN)
endif

PRJOBJDIR=$(TRDIR)/obj
MODULE_MK_DIR=$(PRJOBJDIR)/_dependencies
MODULE_MK_TEST_DIR=$(MODULE_MK_DIR)/test

# external libraries local repository
INCTESTS:=$(filter test %test check %check testbuild help coverage Test%,$(MAKECMDGOALS))

ifneq ($(INCTESTS),)
# The TUSELIB are libraries not needed for the main build but needed for the tests.
NDUSELIB+=$(TUSELIB)
endif

include $(ABSROOT)/core/profiler.mk
# include extern libraries management rules
ifneq ($(INCLUDE_EXTLIB),false)
include $(ABSROOT)/core/module-extlib.mk
endif

# BROWSER was introduced for charm but is not really needed yet...
#BROWSER:=$(word 1,$(shell which chromium firefox chrome edge safari iexplorer firefox-esr 2>/dev/null))
ifneq ($(wildcard $(PRJROOT)/_charm),)
include $(ABSROOT)/charm/main.mk
endif

