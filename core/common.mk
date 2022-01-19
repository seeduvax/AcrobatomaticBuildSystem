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
ifeq ($(COLORS_TCAP),yes)
ABS_PRINT_debug:=env printf "\e[36m[abs-debug]\t%s\e[0m\n" 
ABS_PRINT_info:=env printf "\e[39;1m[abs-info]\t%s\e[0m\n" 
ABS_PRINT_warning:=env printf "\e[35;1m[abs-warning]\t%s\e[0m\n" 
ABS_PRINT_error:=env printf "\e[31;1m[abs-error]\t%s\e[0m\n" 
ABS_PRINT:=env printf "\e[34;1m[[abs-%s]]\t%s\e\0m\n" 
else
ABS_PRINT_debug:=env printf "[abs-debug]\t%s\n" 
ABS_PRINT_info:=env printf "[abs-info]\t%s\n" 
ABS_PRINT_warning:=env printf "[abs-warning]\t%s\n" 
ABS_PRINT_error:=env printf "[abs-error]\t%s\n" 
ABS_PRINT:=env printf "[[abs-%s]]\t%s\n" 
endif
export ABS_PRINT_debug
export ABS_PRINT_info
export ABS_PRINT_warning
export ABS_PRINT_error
export ABS_PRINT

# some vars to store some particular chars for their use in macros.
define _carriage_return_
!!
!!
endef
_carriage_return_:=$(patsubst !!,,$(_carriage_return_))
_space_=$(subst ,, )

##  - LIB_REPO: dependencies repositories. local file path or URL. Repositories
##       shall be list according the expected search order. Use ',' char as
##       separator.
LIB_REPO?=$(ABS_REPO)

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

$(BUILDROOT)/.abs/vars.mk:
	mkdir -p $(@D)
	@$(ABS_PRINT_info) "Generating workspace static global parameters..."
	@echo "" > $@
	@svn info > /dev/null 2>&1 && echo "ABS_SCM_TYPE:=svn" >> $@|| :
	@git status > /dev/null 2>&1 && echo "ABS_SCM_TYPE:=git" >> $@ || :

include $(BUILDROOT)/.abs/vars.mk

$(BUILDROOT)/.abs/$(HOSTNAME)-vars.mk:
	mkdir -p $(@D)
	@$(ABS_PRINT_info) "Generating workspace and host related static global parameters..."
	@echo "" > $@
	@LSBRCMD=`which lsb_release 2>/dev/null` ;\
	release="" ;\
	distId="" ;\
	if [ "$$LSBRCMD" != "" ] ;\
	then \
		distId=`$$LSBRCMD -is | sed 's/ /_/g'`;\
	fi ;\
	if [ ! "$$distId" = "" ] ;\
	then \
		release=`$$LSBRCMD -rs` ;\
		mrelease=`echo $$release | cut -f 1 -d '.'` ;\
	else \
		distId=`uname -o | sed 's:[/ ]:_:g'` ;\
	fi ;\
	case "$$distId"_"$$release" in \
		_) echo "SYSNAME?=UnknownArch" >> $@ ;;\
		Msys*|Cygwin*) echo "Windows";;\
		*) echo "SYSNAME?=$$distId"_"$$mrelease" >> $@;;\
	esac
	@echo "HWNAME?="`uname -m` >> $@

include $(BUILDROOT)/.abs/$(HOSTNAME)-vars.mk

ifeq ($(ARCH),)
##  - ARCH: Architecture (ex: Debian_8_x86_64)
ARCH:=$(SYSNAME)_$(HWNAME)
endif
ifeq ($(findstring WIN,$(ARCH)),WIN)
PATH_SEP:=;
else
PATH_SEP:=:
endif


##  - TRDIR: target root directory (where the installed product image is stored)
TRDIR?=$(BUILDROOT)/$(ARCH)/$(MODE)
TTARGETDIR?=$(TRDIR)/test
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

# external libraries local repository
INCTESTS:=$(filter test %test check %check testbuild help coverage,$(MAKECMDGOALS))

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

