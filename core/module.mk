## ---------------------------------------------------------------------
## ABS: Automated Build System
## See ABS documentation (res #170983b) for more details
##   http://github.com/seeduvax/AcrobatomaticBuildSystem
##   http://www.eduvax.net/gitweb
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

include $(ABSROOT)/core/common.mk

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
$(if $(FILTER_VARIABLES), $(subst |, ,$(subst $(eval) ,;,$(foreach name,$(FILTER_VARIABLES),sed|-i|'s~{$(name)}~$($(name))~g'|$(strip $(1)))));)
endef
# Execute the filtering on a file.
# params: 1-The original path to the file, 2-The output file to filter (must exists)
ifneq ($(FILTER_FILES),)
define executeFiltering
/bin/bash -c "if [[ \"$(FILTER_FILES)\" == "*$(strip $(1))*" ]]; then echo \"Filtering $(2) ...\"; $(call filterCmds, $(2)) fi"
endef
else
define executeFiltering
endef
endif

## 
## Common make targets:
## 
##  - all (default): builds all
.PHONY: all
all: all-impl

##  - clean: removed all files created by the module build process
.PHONY: clean
clean:: clean-module

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

.PHONY: coverage
coverage::

##  - valgrindtest [RUNARGS="<arg> [<arg>]*":  build and run tests with valgrind
.PHONY: valgrindtest
valgrindtest:: testbuild

##  - testbuild [RUNARGS="<arg> [<arg>]*":  build tests
.PHONY: testbuild
testbuild:: all

##  - check: alias for test
.PHONY: check
check:: test

# this target must not defined a rule to avoid issues during parallel builds.
all-impl::

# ---------------------------------------------------------------------
# Automatic derivation of application & module parameters
# ---------------------------------------------------------------------
# object files go in a subdirectory of build dir dedicated to the module
OBJDIR?=$(TRDIR)/obj/$(MODNAME)
# -------------------------------------------------
# module type adaptation
# -------------------------------------------------

MODULE_TYPES_MAP+=$(ABSROOT)/core/module-%.mk:linuxmodule,java,python,library,exe,fileset,absext,arduino \
    $(ABSROOT)/%/main.mk:doc \
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
	@$(call executeFiltering, $<, $@)

etc:: $(CONFIGFILES)

# ---------------------------------------------------------------------
# Misc utility rules
# ---------------------------------------------------------------------
include $(ABSROOT)/core/module-util.mk

# ---------------------------------------------------------------------
# Generic targets
# ---------------------------------------------------------------------
clean-module:
	@$(ABS_PRINT_info) "Cleaning module..."
	@rm -rf $(TARGETFILE) $(OBJDIR) $(CONFIGFILES)

# help rules
help:
	@grep "^## " $(MAKEFILE_LIST) | sed -e 's/^.*## //' ; echo ; echo

# update bootstrap makefile if needed.
ifneq ($(PRESERVEMAKEFILE),true)
Makefile: ../Makefile
	@$(ABS_PRINT_info) "Updating bootstrap makefile."
	@cp $^ $@
endif

## 
## ---------------------------------------------------------------------
##  dependencies beetween modules management
## ---------------------------------------------------------------------
ifeq ($(filter test,$(MAKECMDGOALS)),)
MODDEPS:=$(patsubst %,%.mod.dep,$(USEMOD) $(USELKMOD))
else
MODDEPS:=$(patsubst %,%.mod.dep,$(USEMOD) $(USELKMOD) $(TESTUSEMOD))
endif
## Variables
## - RMODDEP: module redo recurion level
RMODDEP?=1

ifneq ($(RMODDEP),0)
EXPLICIT_MOD_DEP:=.explicit.mod.dep
DECRMODDEP:=$(shell expr $(RMODDEP) - 1)
.PHONY: $(EXPLICIT_MOD_DEP)
else
DECRMODDEP:=0
EXPLICIT_MOD_DEP:=
endif

define moduleDependencyRule
$(OBJDIR)/$(1).mod.dep: $(LASTMODDEP) $(EXPLICIT_MOD_DEP)
	@$$(ABS_PRINT_info) "Build of dependency: $(1) $(if $(EXPLICIT_MOD_DEP),[$(DECRMODDEP)])..."
	@+make -C $(PRJROOT)/$(1) RMODDEP=$(DECRMODDEP)
	@mkdir -p $$(@D)
	@touch $$@

LASTMODDEP:=$(OBJDIR)/$(1).mod.dep
endef

$(foreach entry,$(MODDEPS),$(eval $(call moduleDependencyRule,$(patsubst %.mod.dep,%,$(entry)))))

ifneq ($(SRCFILES),)
$(SRCFILES): $(LASTMODDEP)
else
all: $(LASTMODDEP)
endif
