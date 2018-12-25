## ---------------------------------------------------------------------
## ABS: Automated Build System
## See ABS documentation for more details
## - wiki page: https://pforgerle.public.infrapub.fr.st.space.corp/confluence/display/rdtea332/BuildScripts
## - reference documentation: RD_TEA332-1593
## --------------------------------------------------------------------
## Module level build services
## --------------------------------------------------------------------

# by default module dir is directly under project root dir
ifeq ($(MODROOT),)
	MODROOT:=$(shell pwd)
endif
ifeq ($(PRJROOT),)
	PRJROOT:=$(shell dirname $(MODROOT))
endif

include $(PRJROOT)/.abs/core/common.mk

# remove some default macros
CC=
CPPC=
LD=
SPACECHAR= 

# Buildcript capabilities
# introduced in buildscrip 0.4, may be used to have some to have some fallback
# behavior to support several buildscript versions from imported precompiled
# dist package.
# - linklib : independant extlib's CFLAGS/LDFLAGS settings, see RD_TEA332-776
BUILDSCRIPTS_CAPS:=linklib

SRCFILES:=$(shell find src -type f 2>/dev/null | grep -v "/\.")
# initialize variable that must not be forwared in recursive make call
COBJS:=
CPPOBJS:=
OBJS:=
GENSRC:=
GENOBJS:=
LUA_MDL_ENABLE:=
LUA_MDL_TYPES_FILE:=
LUA_MDL_MODEL_HEADERS:=

# include application global parameters
include $(PRJROOT)/app.cfg

# include module specific parameters
include $(MODROOT)/module.cfg

# include workspace local parameters if any
-include $(PRJROOT)/local.cfg

ifeq ($(REVISION),)
REVISION:=undef
ifeq ($(ABS_SCM_TYPE),svn)
REVISION:=$(shell svnversion)
endif
endif

# identify dev version from tagged version, only when version is not overloaded.
ifeq ($(WORKSPACE_IS_TAG),0)
VERSION:=$(VERSION)d
endif
ifeq ($(ABS_SCM_TYPE),null)
VERSION:=$(VERSION)e
endif

# filterCmd permit to generate the sed commands to replace tokens in input file with FILTER_VARIABLES
# 1st foreach: create sed command (with | instead of space to permit the replacement of spaces with ;)
# 1st subst: replace the spaces between sed command with ; to permit the execution of each sed.
# 2nd subst: replace | with space to get good sed commands.
define filterCmds
$(if $(FILTER_VARIABLES), $(subst |, ,$(subst $(eval) ,;,$(foreach name,$(FILTER_VARIABLES),sed|-i|'s~{$(name)}~$($(name))~g'|$@)));)
endef

# ---------------------------------------------------------------------
#  dependences beetween modules
# ---------------------------------------------------------------------
ifeq ($(filter test,$(MAKECMDGOALS)),)
MODDEPS:=$(patsubst %,$(TRDIR)/.%.mod.dep,$(USEMOD) $(USELKMOD))
else
MODDEPS:=$(patsubst %,$(TRDIR)/.%.mod.dep,$(USEMOD) $(USELKMOD) $(TESTUSEMOD))
endif

$(TRDIR)/.%.mod.dep:
	@$(ABS_PRINT_info) "Request build of dependency: $(USEMOD)..."
	@+make -C $(PRJROOT)/$(patsubst $(TRDIR)/.%.mod.dep,%,$@)

$(OBJS): $(TRDIR)/.$(MODNAME).mod.dep

## 
## Common make targets:
## 
##  - all (default): builds all
.PHONY: all
all: all-impl
	@mkdir -p $(TRDIR) 
	@touch $(TRDIR)/.$(MODNAME).mod.dep

##  - clean: removed all files created by the module build process
.PHONY: clean
clean:: clean-module
	@rm -rf $(TRDIR)/.$(MODNAME).mod.dep

# copy config files
.PHONY: etc
etc:: 

##  - run [RUNARGS="<arg> [<arg>]*": run application
.PHONY: run
run::

##  - debug [RUNARGS="<arg> [<arg>]*": run application in gdb debugger
.PHONY: debug
debug::

##  - test [RUNARGS="<arg> [<arg>]*":  build and run tests
.PHONY: test
test:: testbuild

##  - valgrindtest [RUNARGS="<arg> [<arg>]*":  build and run tests with valgrind
.PHONY: valgrindtest
valgrindtest:: testbuild

##  - testbuild [RUNARGS="<arg> [<arg>]*":  build tests
.PHONY: testbuild
testbuild:: all

##  - check: alias for test
.PHONY: check
check:: test


$(SRCFILES): $(MODDEPS)

# this target must not defined a rule to avoid issues during parallel builds.
all-impl::

# ---------------------------------------------------------------------
# Automatic derivation of application & module parameters
# ---------------------------------------------------------------------
# object files go in a subdirectory of build dir dedicated to the module
OBJDIR?=$(TRDIR)/obj/$(MODNAME)
# external libraries local repository
ifeq ($(TRDIR),$(PRJROOT)/build/$(ARCH)/$(MODE))
EXTLIBDIR?=$(PRJROOT)/build/$(ARCH)/extlib
NA_EXTLIBDIR?=$(PRJROOT)/build/noarch/extlib
else
EXTLIBDIR?=$(TRDIR)/extlib
NA_EXTLIBDIR?=$(TRDIR)/extlib
endif
NDEXTLIBDIR:=$(EXTLIBDIR).nodist
NDNA_EXTLIBDIR:=$(NA_EXTLIBDIR).nodist
INCTESTS:=$(filter test %test check %check testbuild help,$(MAKECMDGOALS))

# include extern libraries management rules
include $(ABSROOT)/core/module-extlib.mk

# -------------------------------------------------
# module type adaptation
# -------------------------------------------------

MODULE_TYPES_MAP+=$(ABSROOT)/core/module-%.mk:linuxmodule,java,python,library,exe,fileset,absext,arduino \
    $(ABSROOT)/%/main.mk:doc,mstrans \
    $(ABSROOT)/core/module-java.mk:jar

comma:=,
define findModTypeInMap
$(filter $(MODTYPE),$(subst $(comma), ,$(word 2,$(subst :, ,$(entry)))))
endef
define getPathForCurrentMod
$(if $(strip $(findModTypeInMap)),$(word 1,$(subst :, ,$(entry))), )
endef

INC_MODULE_FILE:=$(patsubst %,$(foreach entry,$(MODULE_TYPES_MAP),$(getPathForCurrentMod)),$(MODTYPE))
ifneq ($(strip $(INC_MODULE_FILE)),)
include $(INC_MODULE_FILE)
else
$(warning Unknown module type $(MODTYPE), no module specific rules included)
endif

# ---------------------------------------------------------------------
# Config files
# ---------------------------------------------------------------------
CONFIGFILES:=$(patsubst %,$(TRDIR)/%,$(shell find etc -type f 2>/dev/null | grep -v "/.svn/"))

# Copy of config files.
# Use FILTER_FILES to find the config file which must be modified using FILTER_VARIABLES.
$(TRDIR)/etc/%: etc/%
	@$(ABS_PRINT_info) "Copying config file $< ..."
	@mkdir -p $(@D)
	@cp $< $@
	@/bin/bash -c "if [[ \"$(FILTER_FILES)\" == "*$<*" ]]; then echo \"Filtering $@ ...\"; $(filterCmds) fi" 

etc:: $(CONFIGFILES)

# ---------------------------------------------------------------------
# Misc utility rules
# ---------------------------------------------------------------------
include $(ABSROOT)/core/module-util.mk

# ---------------------------------------------------------------------
# Generic targets
# ---------------------------------------------------------------------
clean-module:
	rm -rf $(TARGETFILE) $(OBJDIR) $(CONFIGFILES)

# help rules
help:
	@grep "^## " $(MAKEFILE_LIST) | sed -e 's/^.*## //' ; echo ; echo


