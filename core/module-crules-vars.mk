# Creation of default variables for cross compilation
# CROSS_COMPILE is a wide spread variable name used for cross compilation.
ifeq ($(CROSS_ARCH),mingw)
CROSS_COMPILE?=x86_64-w64-mingw32-
ARCH_EXECUTOR?=wine
else
ifneq ($(CROSS_ARCH),)
CROSS_COMPILE?=$(CROSS_ARCH)-linux-gnu-
ARCH_EXECUTOR?=qemu-$(CROSS_ARCH)-static
endif
endif

# default C flags
CFLAGS+=-I$(ABSROOT)/core/include
ifneq ($(ISWINDOWS),true)
CFLAGS+=-Iinclude -fPIC -I$(TRDIR)/include
else
CFLAGS+=-Iinclude -I$(TRDIR)/include -Wa,-mbig-obj
endif

# default C/C++ commands and flags
# test if not empty because can be set by imported BUILDCHAIN.
ifeq ($(CC),)
CC=$(CROSS_COMPILE)gcc
endif
ifeq ($(CPPC),)
CPPC=$(CROSS_COMPILE)g++
endif
ifeq ($(AR),)
AR=$(CROSS_COMPILE)ar
endif
ifeq ($(LD),)
LD=$(CROSS_COMPILE)g++
endif
ifeq ($(OBJCOPY),)
OBJCOPY=$(CROSS_COMPILE)objcopy
endif

AREXT?=a
SODIR?=lib
ifeq ($(ISWINDOWS),true)
SOEXT?=dll.a
SOPFX?=lib
BINEXT=.exe
else
ifeq ($(CROSS_ARCH),mingw)
SOEXT?=dll
SOPFX?=
BINEXT=.exe
else
SOEXT?=so
SOPFX?=lib
BINEXT=
endif
endif

CC_VERSION:=$(shell $(CC) -dumpversion)

# add extra symbol definition
CFLAGS+=$(patsubst %,-D%,$(DEFINES))

# add coverage flags on coverage target.
ifeq ($(MAKECMDGOALS),coverage)
CFLAGS+=-coverage
LDFLAGS+=-lgcov
endif

# default library mode is DYNAMIC_LIB, STATIC_LIB is disabled
DYNAMIC_LIB?=true
STATIC_LIB?=false

ifeq ($(APPNAME),$(MODNAME))
TARGET_NO_APPNAME=true
endif
ifeq ($(TARGET_NO_APPNAME),true)
TARGET_PARTNAME=$(MODNAME)
else
TARGET_PARTNAME=$(APPNAME)_$(MODNAME)
endif
TARGET_LIB=$(SOPFX)$(TARGET_PARTNAME).$(SOEXT)
TARGET_EXE=$(TARGET_PARTNAME)$(BINEXT)

# Target definition
ifeq ($(MODTYPE),library) 
# target is a library
# build a shared library
# name of shared library file
	TARGET=$(TARGET_LIB)
# shared lib goes into lib subdir of build dir.
	TARGETDIR=$(TRDIR)/$(SODIR)
# cygwin specifics
ifeq ($(ISWINDOWS),true)
	CYGTARGETDIR=$(TRDIR)/bin
ifeq ($(APPNAME),$(MODNAME))
	CYGTARGET=$(APPNAME).dll
else
	CYGTARGET=$(APPNAME)_$(MODNAME).dll
endif
else
	LDFLAGS+=-shared
endif
else
# target is an executable
# executable file name
	TARGET=$(TARGET_EXE)
# executable file goes in bin subdir of build dir.
	TARGETDIR=$(TRDIR)/bin
endif

# target full path
TARGETFILE=$(TARGETDIR)/$(TARGET)
TARGETFILE_LIB=$(TARGETDIR)/$(TARGET_LIB)
TARGETFILE_EXE=$(TARGETDIR)/$(TARGET_EXE)
TARGETARCHIVE=$(TARGETDIR)/$(patsubst %.$(SOEXT),%.$(AREXT),$(TARGET_LIB))

# all the dependencies of this module. Resolve by transitivity among first level dependencies.
ALL_DEPENDENCIES=$(sort $(call getDependenciesByTransitivity,$(call getLibrariesNameFromLinklib,$(LINKLIB)) $(INCLUDE_MODS) $(patsubst %,$(APPNAME)_%,$(USEMOD)),_MOD_CRULES_DEPSVAR_))
# LDFLAGS permit to get the created .so that are not MODTYPE library.
# this variable must be evaluated at the use time because at declaration time, the dependencies are not generated yet.
INCLUDE_PROJ_MODS=$(filter-out $(MODNAME),$(patsubst $(APPNAME)_%,%,$(filter $(PROJECT_INC_MODS),$(ALL_DEPENDENCIES))))
LDFLAGS+=-L$(TRDIR)/$(SODIR)
LDFLAGS+=$(foreach mod,$(USEMOD),$(if $(wildcard $(TRDIR)/$(SODIR)/$(SOPFX)$(APPNAME)_$(mod).$(SOEXT)),-l$(APPNAME)_$(mod),)$(if $(wildcard $(TRDIR)/$(SODIR)/$(SOPFX)$(mod).$(SOEXT)),-l$(mod),))
LDFLAGS+=$(foreach mod,$(INCLUDE_PROJ_MODS),$(if $(wildcard $(TRDIR)/$(SODIR)/$(SOPFX)$(APPNAME)_$(mod).$(AREXT)),-l$(APPNAME)_$(mod),)$(if $(wildcard $(TRDIR)/$(SODIR)/$(SOPFX)$(mod).$(AREXT)),-l$(mod),))

# add paths to used modules' headers & libs.
CFLAGS+=-I$(TRDIR)/include
CFLAGS+=$(foreach mod,$(INCLUDE_PROJ_MODS),$(if $(wildcard $(PRJROOT)/$(mod)/include),-I$(PRJROOT)/$(mod)/include))
LDFLAGS+=$(patsubst %,-l%,$(LINKLIB))

INCLUDE_MODS_EXT=$(filter-out $(PROJECT_INC_MODS),$(ALL_DEPENDENCIES))
INCLUDE_MODS_EXT_LOOKING_PATHS=$(sort $(foreach modExt,$(INCLUDE_MODS_EXT),$(_module_$(modExt)_dir) $(_app_$(modExt)_dir) $(_app_lib$(modExt)_dir)))
INCLUDE_MODS_EXT_CPATHS=$(foreach path,$(INCLUDE_MODS_EXT_LOOKING_PATHS),$(wildcard $(path)/include))
CFLAGS+=$(foreach extPath,$(INCLUDE_MODS_EXT_CPATHS),-I$(extPath))
INCLUDE_MODS_EXT_LDPATHS+=$(foreach path,$(INCLUDE_MODS_EXT_LOOKING_PATHS),$(filter-out %/library.json,$(wildcard $(path)/lib*)))
LDFLAGS+=$(foreach extPath,$(INCLUDE_MODS_EXT_LDPATHS),-L$(extPath))

# if advanced dependency management is disable, all the external libs are used for the compilation.
ifeq ($(ADV_DEPENDS_MANAGEMENT),false)
EXT_LIBS_WITHOUT_JSON=$(foreach lib,$(ALL_LIBS_LOADED),$(if $(wildcard $(_app_$(lib)_dir)/library.json),,$(_app_$(lib)_dir)))
CFLAGS+=$(foreach extPath,$(EXT_LIBS_WITHOUT_JSON),-I$(extPath)/include)
EXT_LIBS_WITHOUT_JSON_LDPATHS+=$(foreach path,$(EXT_LIBS_WITHOUT_JSON),$(filter-out %/library.json,$(wildcard $(path)/lib*)))
LDFLAGS+=$(foreach extPath,$(EXT_LIBS_WITHOUT_JSON_LDPATHS),-L$(extPath))
endif

# library dir list (to be forwarded to LD_LIBRARY_PATH env var before running the app)
LDLIBP=$(subst $(_space_),:,$(patsubst -L%,%,$(filter -L%,$(LDFLAGS))))
RUNPATH:=$(TRDIR)/bin$(subst $(_space_),,$(patsubst %,:$(EXTLIBDIR)/%/bin,$(USELIB_FOR_PATH))):$(PATH)

LDRUNP?=$$ORIGIN/../lib

## 
## ---------------------------------------------------------------------
## Compilation flags by compilation modes
## ---------------------------------------------------------------------
## DEBUGCFLAGS: additional compiler option to set on debug mode only (default: empty)
IDENTCFLAGS:=-D__APPNAME__='$(APPNAME)' -D__MODNAME__='$(MODNAME)'
ifeq ($(MODE),debug)
# debugging symbols, no optimisation, optionnal flags for debug mode
# defines must not contains - => so replace by _
CFLAGS+=-g -D_$(subst -,_,$(APPNAME))_$(subst -,_,$(MODNAME))_debug -D_abs_trace_debug $(IDENTCFLAGS) $(DEBUGCFLAGS)
else
# some optimisation, no debbugging symbol, optionnal flags for release mode
## RELEASECFLAGS: additional compiler option to set on release mode only (default: -O3)
RELEASECFLAGS?=-O3
# defines must not contains - => so replace by _
CFLAGS+=-D_$(subst -,_,$(APPNAME))_$(subst -,_,$(MODNAME))_release $(IDENTCFLAGS) $(RELEASECFLAGS)
endif

# sanitizer
ifeq ($(ACTIVATE_SANITIZER),true)
SANITIZERS+=address undefined
ifneq ($(filter clang%,$(CPPC)),)
#-shared-libasan needed for clang
CFLAGS+=-shared-libasan
LDFLAGS+=-shared-libasan
TLDPRELOAD+=$(shell $(CPPC) $(CFLAGS) --print-file-name=libclang_rt.asan-x86_64.so)
else
TLDPRELOAD+=$(shell $(CPPC) $(CFLAGS) --print-file-name=libasan.so)
endif #ifneq ($(filter clang%,$(CPPC)),)
else ifeq ($(ACTIVATE_SANITIZER),thread)
SANITIZERS+=thread
TLDPRELOAD+=$(shell $(CPPC) $(CFLAGS) --print-file-name=libtsan.so)
ACTIVATE_SANITIZER:=true
endif

ifeq ($(ACTIVATE_SANITIZER),true)
SANITIZERS_ARGS=$(patsubst %,-fsanitize=%,$(SANITIZERS))
CFLAGS+=$(SANITIZERS_ARGS) -fno-omit-frame-pointer
LDFLAGS+=$(SANITIZERS_ARGS)
endif
TLDPRELOADFORMATTED=$(subst $(_space_),:,$(TLDPRELOAD))

GEN_DEP_FLAGS=-MMD -MF $@.d
EXTRA_CFLAGS=$(GEN_DEP_FLAGS)
EXTRA_CXXFLAGS=$(GEN_DEP_FLAGS)

ifneq ($(filter clang%,$(CC)),)
EXTRA_CFLAGS+=-MJ $@.json
TCFLAGS+=-MJ $@.json
define gen-json-cc
endef
define gen-json-test-cc
endef
else
define gen-json-cc
@echo '{"directory":"$(MODROOT)","command":"$(CC) $(CFLAGS) -c $< -o $@","file":"$<","output":"$@"},' > $@.json
endef
define gen-json-test-cc
@echo '{"directory":"$(MODROOT)","command":"$(CC) $(CFLAGS) $(TCFLAGS) -include $(patsubst %.o,%.h,$@) -MMD -MF -c $< -o $@","file":"$<","output":"$@"},' > $@.json
endef
endif

ifneq ($(filter clang%,$(CPPC)),)
EXTRA_CXXFLAGS+=-MJ $@.json
TCFLAGS+=-MJ $@.json
define gen-json-cppc
endef
define gen-json-test-cppc
endef
else
define gen-json-cppc
@echo '{"directory":"$(MODROOT)","command":"$(CPPC) $(CXXFLAGS) $(CFLAGS) -c $< -o $@","file":"$<","output":"$@"},' > $@.json
endef
define gen-json-test-cppc
@echo '{"directory":"$(MODROOT)","command":"$(CPPC) $(CXXFLAGS) $(CFLAGS) $(TCFLAGS) -include $(patsubst %.o,%.h,$@) -MMD -MF -c $< -o $@","file":"$<","output":"$@"},' > $@.json
endef
endif

define win-patch-dep
@sed -i "s,"`cygpath -m $(BUILDROOT)`",$(BUILDROOT),g" $@.d
@sed -i "s,"`cygpath -m $$HOME`",$$HOME,g" $@.d
endef

define cc-command-base
@$(ABS_PRINT_info) "Compiling $< ..."
@mkdir -p $(@D)
$(gen-json-cc)
@$(call executeAndLogCmd,$(CC) $(CFLAGS) $(EXTRA_CFLAGS) -c $< -o $@)
endef
ifeq ($(ISWINDOWS),true)
define cc-command
$(cc-command-base)
$(win-patch-dep)
endef
else
define cc-command
$(cc-command-base)
endef
endif

define cxx-command-base
@$(ABS_PRINT_info) "Compiling $< ..."
@mkdir -p $(@D)
$(gen-json-cppc)
@$(call executeAndLogCmd,$(CPPC) $(CXXFLAGS) $(CFLAGS) $(EXTRA_CXXFLAGS) -c $< -o $@)
endef
ifeq ($(ISWINDOWS),true)
define cxx-command
$(cxx-command-base)
$(win-patch-dep)
endef
else
define cxx-command
$(cxx-command-base)
endef
endif

CRULES_VAR_LINKED_LIBS=$(sort $(filter -l%,$(LDFLAGS)))
CRULES_VAR_LINKED_DIRS=$(sort $(filter -L%,$(LDFLAGS)))
# --rpath-link permit to the linker to find shared libraries (needed for cross compiler linker for exe generation).
CRULES_VAR_RPATH_LINKS=$(patsubst -L%,-Wl$(_comma_)--rpath-link=%,$(CRULES_VAR_LINKED_DIRS))
CRULES_VAR_LDFLAGS=
ifneq ($(MODTYPE),library) 
CRULES_VAR_LDFLAGS+=$(CRULES_VAR_RPATH_LINKS)
endif
CRULES_VAR_LDFLAGS+=$(filter-out -l% -L%,$(LDFLAGS)) $(CRULES_VAR_LINKED_DIRS) $(CRULES_VAR_LINKED_LIBS)

# generate the additionnals LDFLAGS to link lib on Windows.
# 1: destination import lib
# 2: generated objects
define getWindowsLibLDFlags
-Wl,--out-implib=$@ \
-Wl,--export-all-symbols \
-Wl,--enable-auto-import \
-Wl,--whole-archive $(OBJS) \
-Wl,--no-whole-archive
endef

# on none Windows, add creation of static archive
# for static lib, remove vinfo.o and rename lib.so -> lib.a
ifneq ($(ISWINDOWS),true)
define ar-command-lib
@$(ABS_PRINT_info) "Archiving $@ ..."
@mkdir -p $(TARGETDIR)
@$(call executeAndLogCmd,LD_RUN_PATH='$(LDRUNP)' $(AR) rcs $@ $(OBJS_NO_VINFO))
endef
define ld-command-lib
@$(ABS_PRINT_info) "Linking $@ ..."
@mkdir -p $(TARGETDIR)
@$(call writeToBuildLogs,$(MODNAME) linked to $(sort $(patsubst -l%,%,$(CRULES_VAR_LINKED_LIBS))))
@$(call executeAndLogCmd,LD_RUN_PATH='$(LDRUNP)' LD_LIBRARY_PATH=$(LDLIBP) $(LD) -o $@ $(OBJS) $(CRULES_VAR_LDFLAGS))
endef
define ld-command-exe
$(ld-command-lib)
endef
else #ifeq ($(ISWINDOWS),true)
define ld-command-lib
@$(ABS_PRINT_info) "Linking $@ ..."
@mkdir -p $(TARGETDIR) $(CYGTARGETDIR)
@$(call executeAndLogCmd,$(LD) -shared -o $(CYGTARGETDIR)/$(CYGTARGET) $(call getWindowsLibLDFlags,$@,$(OBJS)) $(LDFLAGS))
endef
define ld-command-exe
@$(ABS_PRINT_info) "Linking $@ ..."
@mkdir -p $(TARGETDIR) $(CYGTARGETDIR)
@$(call writeToBuildLogs,$(MODNAME) linked to $(sort $(patsubst -l%,%,$(CRULES_VAR_LINKED_LIBS))))
@$(call executeAndLogCmd,$(LD) -o $@ -Wl$(_comma_)--enable-auto-import $(OBJS) $(LDFLAGS))
endef
endif # ifneq ($(ISWINDOWS),true)
