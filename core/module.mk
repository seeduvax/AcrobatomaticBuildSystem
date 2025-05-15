## ---------------------------------------------------------------------
## ABS: Automated Build System
## See ABS documentation (res #170983b) for more details
##   http://github.com/seeduvax/AcrobatomaticBuildSystem
##   http://www.eduvax.net/gitweb
## 
## --------------------------------------------------------------------
## Module level build services
## --------------------------------------------------------------------
## 
## ---------------------------------------------------------------------
## Automatic derivation of application & module parameters
## ---------------------------------------------------------------------
## 
## Module common variables:
## 
## - USEMOD: list of dependences with another modules of this project.
## - LINKLIB: list of externals dependencies to link with this module.
##         To link another module of an ABS project, use $(APPNAME)_$(MODULE)
##         For C/C++ module, the lib must include the library binary.
##         This is the name of binary file. If name differ from library archive name,
##         use INCLUDE_MODS
## - INCLUDE_MODS: list of externals dependencies needed for this module.
##         This module will have a dependency to theses include_mods
##         To include another module of an ABS project, use $(APPNAME)_$(MODULE)
##

# by default module dir is directly under project root dir
ifeq ($(MODROOT),)
	MODROOT:=$(abspath .)
endif
ifeq ($(PRJROOT),)
	PRJROOT:=$(dir $(MODROOT))
endif
MODNAME?=$(notdir $(MODROOT))

# remove some default macros
# the variable CC, CXX, LD, AR, ... are builtin variables already set by make
CC=
CPPC=
LD=
AR=
SPACECHAR= 
# Path to receive external source files
EXT_SRC_DIR=$(BUILDROOT)/extsrc

# Buildcript capabilities
# introduced in buildscrip 0.4, may be used to have some fallback
# behavior to support several buildscript versions from imported precompiled
# dist package.
# - linklib : independant extlib's CFLAGS/LDFLAGS settings, see RD_TEA332-776
BUILDSCRIPTS_CAPS:=linklib

# initialize variable that must not be forwared in recursive make call
COBJS:=
CPPOBJS:=
OBJS:=
GENSRC:=
GENOBJS:=

include $(ABSROOT)/core/common.mk

include $(LOAD_MODDEPS_FILE)

# include EXTLIBMAKES after moddeps.mk to have all USELIB
$(eval $(call extlib_updates_deps))

# object files go in a subdirectory of build dir dedicated to the module
OBJDIR?=$(PRJOBJDIR)/$(MODNAME)
EXT_MODSRC_DIR=$(OBJDIR)/extsrc

TR_APP_INCLUDE_DIR=$(TRDIR)/include/$(APPNAME)
TR_MOD_INCLUDE_DIR=$(TR_APP_INCLUDE_DIR)/$(MODNAME)

# ultimate wildcard to eliminate files with space
SRCFILES:=$(wildcard $(call find,src,*))
EXTSRCFILES:=

TTARGETDIR?=$(TRDIR)/test
TEST_REPORT_PATH:=$(TTARGETDIR)/$(APPNAME)_$(MODNAME).xml

DISTINFO_FILE=$(OBJDIR)/$(DISTINFO_FILENAME)
TARGETFILES+=$(DISTINFO_FILE)

ifeq ($(REVISION),)
REVISION:=undef
ifeq ($(ABS_SCM_TYPE),svn)
REVISION:=$(shell svnversion)
endif
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

# NEEDED_PROJ_MODS permit to add dependency between mods but without doing link between generated libraries.
NEEDED_PROJ_MODS=$(sort $(USEMOD) $(patsubst $(APPNAME)_%,%,$(filter $(PROJECT_INC_MODS),$(INCLUDE_MODS))))

# ---------------------------------------------------------------------
# Config files
# ---------------------------------------------------------------------
# the variable CONFIGFILES can be used for rules dependencies in abs extensions.
CONFIGFILES:=$(patsubst %,$(TRDIR)/%,$(call filter_out_substr,/.svn/,$(call find,etc,*)))
TARGETFILES+=$(patsubst %,$(TRDIR)/%,$(call filter_out_substr,/.svn/,$(call find,etc,*)))

## 
## Common make targets:
##
##  - all (default): builds all
.PHONY: all
all: all-impl

##  - clean: removed all files created by the module build process
.PHONY: clean
clean:: clean-module

##  - run [RUNARGS="<arg> [<arg>]*"]: run application
.PHONY: run
run::

##  - debug [RUNARGS="<arg> [<arg>]*"]: run application in gdb debugger
.PHONY: debug
debug::

##  - test [RUNARGS="<arg> [<arg>]*"]:  build and run tests
.PHONY: test
test:: testbuild

.PHONY: coverage
coverage::

##  - valgrindtest [RUNARGS="<arg> [<arg>]*"]:  build and run tests with valgrind
.PHONY: valgrindtest
valgrindtest:: testbuild

##  - testbuild [RUNARGS="<arg> [<arg>]*"]:  build tests
.PHONY: testbuild
testbuild:: all

##  - check: alias for test
.PHONY: check
check:: test

# ---------------------------------------------------------------------
# external sources / svn checkout
# ---------------------------------------------------------------------
# .....................................................................
# external sources / svn checkout
ifneq ($(SVN_CHECKOUTS),)

$(EXT_SRC_DIR)/svn/%/.mk:
	@mkdir -p $(@D)
	svn co $(word 2,$(subst =, ,$(filter $(patsubst $(EXT_SRC_DIR)/svn/%/.mk,%,$@)=%,$(SVN_CHECKOUTS)))) $(@D)
	@echo 'EXTSRCFILES+=$$(call find,$(@D),*.c *.cpp)' > $@

include $(foreach entry,$(SVN_CHECKOUTS),$(patsubst %,$(EXT_SRC_DIR)/svn/%/.mk,$(word 1,$(subst =, ,$(entry)))))

endif

include $(ABSROOT)/core/module-srcarchive.mk

# -------------------------------------------------
# module type adaptation
# -------------------------------------------------

MODULE_TYPES_MAP+=$(ABSROOT)/core/module-%.mk:linuxmodule,java,rust,python,typescript,library,exe,fileset,absext,arduino,maven \
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

# include resolved file in case new libs have been added to dependencies.
$(eval $(call extlib_updates_deps))

# Copy of config files.
# Use FILTER_FILES to find the config file which must be modified using FILTER_VARIABLES.
$(TRDIR)/etc/%: etc/%
	@$(ABS_PRINT_info) "Copying config file $< ..."
	@mkdir -p $(@D)
	@[ -L $@ ] && unlink $@ || true
	@cp $< $@
	@$(call executeFiltering, $<, $@)

# ---------------------------------------------------------------------
# Misc utility rules
# ---------------------------------------------------------------------
include $(ABSROOT)/core/module-util.mk

# ---------------------------------------------------------------------
# Generic targets
# ---------------------------------------------------------------------
# this target must not defined a rule to avoid issues during parallel builds.
all-impl:: $(TARGETFILES)

clean-module:
	@$(ABS_PRINT_info) "Cleaning module..."
	@rm -rf $(TARGETFILES) $(OBJDIR)

# update bootstrap makefile if needed.
ifneq ($(PRESERVEMAKEFILE),true)
# Keep this jobs to be able to update old projects.
Makefile: ../Makefile
	@$(ABS_PRINT_info) "Updating bootstrap makefile."
	@echo "# Generated make bootstrap, do not edit. Edit module.cfg to configure module build." > $@.tmp	
	@echo "include $<" >> $@.tmp
	@mv $@.tmp $@
endif

### 
### ---------------------------------------------------------------------
###  Dependencies beetween modules management
### ---------------------------------------------------------------------
ifeq ($(filter clean% new% showvar,$(MAKECMDGOALS)),)

# do not recreate .depready file to avoid recompilation of all objects when a dependency changed.
.PHONY: $(PRJOBJDIR)/%/.depready
$(PRJOBJDIR)/%/.depready:
	@test -f $@ || touch $@

# recompile all if a dependency changed.
NEEDED_FOR_OBJS+=$(DEFAULT_EXTLIBMAKES) $(PRJOBJDIR)/$(MODNAME)/.depready

$(OBJS): $(NEEDED_FOR_OBJS)

NOBUILD_MODS_IN_DEPS=$(filter $(NOBUILD),$(NEEDED_PROJ_MODS))
ifneq ($(NOBUILD_MODS_IN_DEPS),)
NOTHING:=$(shell $(call writeToBuildLogs,Can't build because of deactivated dependency: $(NOBUILD_MODS_IN_DEPS)))
$(error $(MODNAME): can't build because of deactivated dependency: $(NOBUILD_MODS_IN_DEPS))
endif

endif

# DISABLE_USELIB_PROPAGATION permit to not propagate USELIB or NDUSELIB defined in the module.cfg
ifneq ($(DISABLE_USELIB_PROPAGATION),true)
PROPAGATE_USELIB=true
endif

# generation of the distinfo.mk to have all uselib even if brought by an abs extension.
$(DISTINFO_FILE): $(DEFAULT_EXTLIBMAKES)
	@mkdir -p $(@D)
	@printf 'ifeq ($$(_DIST_INFO_$(MODNAME)_loaded_),)\n'\
'_DIST_INFO_$(MODNAME)_loaded_=true\n'\
'include $$(patsubst %%,$$(TRDIR)/obj/%%/$(DISTINFO_FILENAME),$(NEEDED_PROJ_MODS))\n'\
'_module_$(APPNAME)_$(MODNAME)_alluselib=$(if $(PROPAGATE_USELIB),$(USELIB))\n'\
'_module_$(APPNAME)_$(MODNAME)_uselib=$$(filter-out $$(USELIB),$$(_module_$(APPNAME)_$(MODNAME)_alluselib))\n'\
'_modules_$(APPNAME)_uselib+=$$(_module_$(APPNAME)_$(MODNAME)_uselib)\n'\
'_module_$(APPNAME)_$(MODNAME)_depends=$(sort $(call getLibrariesNameFromLinklib,$(LINKLIB)) $(INCLUDE_MODS) $(patsubst %,$(APPNAME)_%,$(USEMOD)))\n\n'\
'endif' > $@

$(PRJOBJDIR)/%/.done: $(DEFAULT_EXTLIBMAKES)
	@$(ABS_PRINT_info) "==============="
	@$(ABS_PRINT_info) "$(MODNAME): Build of dependency: $*"
	@+make $(MMARGS) MODE=$(MODE) -C $(PRJROOT)/$*
	@date > $@
