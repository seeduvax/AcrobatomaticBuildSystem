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
# introduced in buildscrip 0.4, may be used to have some fallback
# behavior to support several buildscript versions from imported precompiled
# dist package.
# - linklib : independant extlib's CFLAGS/LDFLAGS settings, see RD_TEA332-776
BUILDSCRIPTS_CAPS:=linklib

# xtype permit to get symbolic links too. Important for fileset module type.
SRCFILES:=$(shell find src -xtype f 2>/dev/null | grep -v "/\.")
# initialize variable that must not be forwared in recursive make call
COBJS:=
CPPOBJS:=
OBJS:=
GENSRC:=
GENOBJS:=
LUA_MDL_ENABLE:=
LUA_MDL_TYPES_FILE:=
LUA_MDL_MODEL_HEADERS:=

## Level of dependency management
# Possible values: DISABLED, FIRST, NEXT
DEPS_MNGMT_LEVEL?=FIRST

include $(ABSROOT)/core/common.mk

TTARGETDIR?=$(TRDIR)/test
TEST_REPORT_PATH:=$(TTARGETDIR)/$(APPNAME)_$(MODNAME).xml

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

# ---------------------------------------------------------------------
# Automatic derivation of application & module parameters
# ---------------------------------------------------------------------
# object files go in a subdirectory of build dir dedicated to the module
OBJDIR?=$(PRJOBJDIR)/$(MODNAME)
# log containing all commands executed to generate objects
BUILDLOG=$(PRJOBJDIR)/build.log

# Variable for the module dependencies management.
MODULE_MK_PATH=$(MODULE_MK_DIR)/module_$(APPNAME)_$(MODNAME).mk
MODULE_MK_TEST_PATH=$(MODULE_MK_TEST_DIR)/module_$(APPNAME)_$(MODNAME).mk

MODULE_MK_OBJ_PATH=$(OBJDIR)/module.mk

# these variables will be modified later by reading module.mk files.
ABS_INCLUDE_MODS+=
ABS_INCLUDE_TESTMODS+=

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
# Config files
# ---------------------------------------------------------------------
CONFIGFILES:=$(patsubst %,$(TRDIR)/%,$(shell find etc -type f 2>/dev/null | grep -v "/.svn/"))


# -------------------------------------------------
# module type adaptation
# -------------------------------------------------

MODULE_TYPES_MAP+=$(ABSROOT)/core/module-%.mk:linuxmodule,java,python,library,exe,fileset,absext,arduino \
    $(ABSROOT)/%/main.mk:doc \
    $(ABSROOT)/core/module-java.mk:jar \
	$(ABSROOT)/%/main.mk:fpga

define findModTypeInMap
$(filter $(MODTYPE),$(subst $(_comma_), ,$(word 2,$(subst :, ,$(entry)))))
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
include $(ABSROOT)/core/module-depends.mk

DEFAULT_ABS_EXISTING_LIBS=$(foreach mod,$(DEFAULT_ABS_INCLUDE_MODS),$(if $(_module_$(mod)_dir)$(_app_$(mod)_dir),$(mod),$(if $(_app_lib$(mod)_dir),lib$(mod))))
DEFAULT_ABS_EXISTING_TESTLIBS=$(foreach mod,$(DEFAULT_ABS_INCLUDE_TESTMODS),$(if $(_module_$(mod)_dir)$(_app_$(mod)_dir),$(mod),$(if $(_app_lib$(mod)_dir),lib$(mod))))
DEPS_LIBS_MK=$(foreach mod,$(DEFAULT_ABS_EXISTING_LIBS),$(MODULE_MK_DIR)/module_$(mod).mk)
DEPS_TESTLIBS_MK=$(foreach mod,$(DEFAULT_ABS_EXISTING_TESTLIBS) $(DEFAULT_ABS_EXISTING_LIBS),$(MODULE_MK_TEST_DIR)/module_$(mod).mk)
PROJDEPS_MODS_MK=$(foreach mod,$(PROJECT_MODS),$(MODULE_MK_DIR)/module_$(mod).mk)

ALL_DEPS_SRC_FILES=$(foreach mod,$(filter-out $(MODNAME),$(MODULES_DEPS)),$(wildcard $(PRJROOT)/$(mod)/src/*) $(wildcard $(PRJROOT)/$(mod)/include/*))

CURRENT_DEPENDENCY_FILE:=$(PRJOBJDIR)/currentDependencies

ifeq ($(DEPS_MNGMT_LEVEL),DISABLED)
DEPENDENCY_FILE:=$(OBJDIR)/noDependencyCompilation
$(DEPENDENCY_FILE):
	@mkdir -p $(@D)
	@$(ABS_PRINT_debug) "$(MODNAME): Dependency management disabled"
	@touch $@

else #ifeq ($(DEPS_MNGMT_LEVEL),DISABLED)
DEPENDENCY_FILE:=$(OBJDIR)/dependencyCompilation
$(DEPENDENCY_FILE): $(EXTLIBMAKES) $(ALL_DEPS_SRC_FILES)
	@mkdir -p $(@D)
	@mkdir -p $(PRJOBJDIR)
	@$(ABS_PRINT_debug) "Creation of $@"
ifeq ($(DEPS_MNGMT_LEVEL),FIRST)
	@echo "" > $(CURRENT_DEPENDENCY_FILE)
endif
	@+for mod in $(sort $(ALL_NEEDED_MODS)); do \
		egrep -q $$mod $(CURRENT_DEPENDENCY_FILE) || (\
			$(ABS_PRINT_info) "$(MODNAME): Build of dependency: $$mod" && \
			echo $$mod >> $(CURRENT_DEPENDENCY_FILE) && \
			DEPS_MNGMT_LEVEL="NEXT" make $(MMARGS) MODE=$(MODE) -C $(PRJROOT)/$$mod && \
			$(ABS_PRINT_debug) "$(MODNAME): End processing mod '$$mod'"); \
		done
ifeq ($(DEPS_MNGMT_LEVEL),FIRST)
	@rm -f $(CURRENT_DEPENDENCY_FILE)
endif
	@touch $@

endif # ifeq($(DEPS_MNGMT_LEVEL),DISABLED)

$(MODULE_MK_OBJ_PATH): module.cfg
	@$(ABS_PRINT_debug) "Creation of $@"
	@mkdir -p $(@D)
	@echo "_module_$(APPNAME)_$(MODNAME)_depends:=$(foreach lib,$(sort $(DEFAULT_ABS_EXISTING_LIBS)),$(lib))" > $@

$(MODULE_MK_PATH): $(MODULE_MK_OBJ_PATH) $(DEPS_LIBS_MK) module.cfg
	@$(ABS_PRINT_debug) "Creation of project module $@"
	@mkdir -p $(@D)
	@echo "" > $@.tmp
	@$(foreach modMk,$(DEPS_LIBS_MK),echo "-include $(modMk)" >> $@.tmp;)
	@echo "ABS_INCLUDE_MODS+=$(sort $(DEFAULT_ABS_EXISTING_LIBS))" >> $@.tmp
	@echo "_app_$(APPNAME)_dir:=$(TRDIR)" >> $@.tmp
	@echo "_module_$(APPNAME)_$(MODNAME)_dir:=$(TRDIR)" >> $@.tmp
	@mv $@.tmp $@
	
$(MODULE_MK_TEST_PATH): $(MODULE_MK_OBJ_PATH) $(DEPS_TESTLIBS_MK) module.cfg
	@$(ABS_PRINT_debug) "Creation of project test module $@"
	@mkdir -p $(@D)
	@echo "" > $@.tmp
	@$(foreach modMk,$(DEPS_TESTLIBS_MK),echo "-include $(modMk)" >> $@.tmp;)
	@echo "ABS_INCLUDE_TESTMODS+=$(sort $(DEFAULT_ABS_EXISTING_TESTLIBS) $(DEFAULT_ABS_EXISTING_LIBS))" >> $@.tmp
	@echo "_app_$(APPNAME)_dir:=$(TRDIR)" >> $@.tmp
	@echo "_module_$(APPNAME)_$(MODNAME)_dir:=$(TRDIR)" >> $@.tmp
	@mv $@.tmp $@

$(PROJDEPS_MODS_MK): $(DEPENDENCY_FILE)

PROJECT_MODS_LINED=$(subst $(_space_),|,$(PROJECT_MODS))
define createModuleMkFile
	$(call __createModuleMkFile,$1,echo "|$(PROJECT_MODS_LINED)|" | grep -q "|$*|")
endef

define __createModuleMkFile
	@$2 && $(ABS_PRINT_debug) "Reading of $@ (project module)" || $(ABS_PRINT_debug) "Creation of $@ (external module)"
	@$2 || mkdir -p $(@D)
	@$2 || echo "" > $@.tmp
	@# when _module_$*_depends exists, use it to get dependencies of the module/app.
	@$2 || test -z "$(_module_$*_depends)" || (\
		$(foreach depend,$(sort $(_module_$*_depends)),echo "-include $(@D)/module_$(depend).mk" >> $@.tmp &&) \
		echo "$(1)+=$(sort $(_module_$*_depends))" >> $@.tmp)
	@# when _module_$*_depends not exists, use the variable _app_$*_depends to get the dependencies of the app.
	@$2 || test -n "$(_module_$*_depends)" || test -z "$(_app_$*_depends)" || (\
		$(foreach depend,$(sort $(_app_$*_depends)),echo "-include $(@D)/module_$(depend).mk" >> $@.tmp &&) \
		echo "$(1)+=$(sort $(_app_$*_depends))" >> $@.tmp)
	@# These variables to permit app.mk to find module/app
	@$2 || test -z "$(_app_$*_dir)" || echo "_app_$*_dir?=$(_app_$*_dir)" >> $@.tmp
	@$2 || test -z "$(_module_$*_dir)" || echo "_module_$*_dir?=$(_module_$*_dir)" >> $@.tmp
	@$2 || mv $@.tmp $@
endef

# this rule only execute its command if the mod is not a project mod. 
# (one rule because cannot distinct modules of two project with almost same name ex: 'proj' and 'proj_lkm')
$(MODULE_MK_DIR)/module_%.mk:
	$(call createModuleMkFile,ABS_INCLUDE_MODS)
	
$(MODULE_MK_TEST_DIR)/module_%.mk:
	$(call createModuleMkFile,ABS_INCLUDE_TESTMODS)

ifneq ($(INCTESTS),)

include $(MODULE_MK_TEST_PATH)

endif # ifneq ($(INCTESTS),)

# this include permit to generate the full ABS_INCLUDE_MODS (including externals dependencies and transitionnal dependencies.)
include $(MODULE_MK_PATH)

ifneq ($(SRCFILES),)
$(SRCFILES): $(MODULE_MK_PATH) $(MODULE_MK_TEST_PATH)
else
all: $(MODULE_MK_PATH) $(MODULE_MK_TEST_PATH)
endif
