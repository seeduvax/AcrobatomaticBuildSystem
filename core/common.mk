## 
## Global overloadable variables:
## 
##  - MODE: compilation mode
##          debug (default): with debug symbols, without compiler 
##                           optimizations
##          release: without debug symbols, with some compiler
##                           optimizations
MODE?=debug
ABSROOT?=$(ABSWS)/abs-$(VABS)
# macro for pretty message printi, use color if available
COLORS_TCAP:=$(shell ncolors=`tput colors` 2>/dev/null ; ( [ "$$ncolors" != "" ] && [ "$$ncolors" -ge 0 ] ) && echo yes || echo no)
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
# automatic platform identification.
ifeq ($(SYSNAME),)
ABS_GET_OS_DESCR:=LSBRCMD=`which lsb_release 2>/dev/null` ;\
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
		_) echo "UnknownArch" ;;\
		Msys*|Cygwin*) echo "Windows";;\
		*) echo "$$distId"_"$$mrelease";;\
	esac
SYSNAME:=$(shell $(ABS_GET_OS_DESCR))
endif
ifeq ($(HWNAME),)
HWNAME:=$(shell uname -m)
endif
ifeq ($(ARCH),)
##  - ARCH: Architecture (ex: Debian_8_x86_64)
ARCH:=$(SYSNAME)_$(HWNAME)
endif
ifeq ($(findstring WIN,$(ARCH)),WIN)
PATH_SEP:=;
else
PATH_SEP:=:
endif


##  - BUILDROOT: build root directory
BUILDROOT?=$(PRJROOT)/build
##  - TRDIR: target root directory (where the installed product image is stored)
TRDIR?=$(BUILDROOT)/$(ARCH)/$(MODE)
TTARGETDIR?=$(TRDIR)/test

ABS_SCM_TYPE=null
ifneq ($(wildcard $(PRJROOT)/.git),)
ABS_SCM_TYPE:=git
ABS_GIT_DESCR:=$(shell git describe --tags)
endif
ifneq ($(wildcard $(PRJROOT)/.svn),)
ABS_SCM_TYPE:=svn
endif

# identify dev version from tagged version, only when version is not overloaded.
VERSION_OVERLOADED:=$(filter VERSION=%,$(MAKEOVERRIDES))
ifeq ($(ABS_SCM_TYPE),svn)
WORKSPACE_IS_TAG:=$(shell LANG=C svn info | grep "^URL:" | grep -c "/tags/")
REVISION:=$(shell svnversion)
endif
ifeq ($(ABS_SCM_TYPE),git)
 ifeq ($(ABS_GIT_DESCR),$(APPNAME)-$(VERSION))
WORKSPACE_IS_TAG:=1
 else
WORKSPACE_IS_TAG:=0
REVISION:=$(subst $(APPNAME)-%,%,$(shell git describe --tags))
  ifneq ($(shell LANG=C git status | grep -c modified),0)
REVISION:=$(REVISION)M
  endif
 endif
endif
ifneq ($(VERSION_OVERLOADED),)
WORKSPACE_IS_TAG:=1
endif
