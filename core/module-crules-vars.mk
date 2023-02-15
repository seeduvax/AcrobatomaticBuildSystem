# default C flags
CFLAGS+=-I$(ABSROOT)/core/include
ifneq ($(ISWINDOWS),true)
CFLAGS+=-Iinclude -fPIC -I$(TRDIR)/include
else
CFLAGS+=-Iinclude -I$(TRDIR)/include -Wa,-mbig-obj
endif

# default C/C++ commands and flags
ifeq ($(CC),)
CC=gcc
endif
ifeq ($(CPPC),)
CPPC=g++
endif
ifeq ($(LD),)
LD=g++
endif
ifeq ($(ISWINDOWS),true)
SOEXT?=dll.a
SOPFX?=lib
SODIR?=lib
BINEXT=.exe
else
SOEXT?=so
SOPFX?=lib
SODIR?=lib
BINEXT=
endif

CC_VERSION:=$(shell $(CC) -dumpversion)

# add extra symbol definition
CFLAGS+=$(patsubst %,-D%,$(DEFINES))

# add coverage flags on coverage target.
ifeq ($(MAKECMDGOALS),coverage)
CFLAGS+=-coverage
LDFLAGS+=-lgcov
endif

# Target definition
ifeq ($(MODTYPE),library) 
# target is a library
# build a shared library
# name of shared library file
ifeq ($(APPNAME),$(MODNAME))
	TARGET=$(SOPFX)$(APPNAME).$(SOEXT)
else
	TARGET=$(SOPFX)$(APPNAME)_$(MODNAME).$(SOEXT)
endif
# shared lib goes into lib subdir of build dir.
	TARGETDIR=$(TRDIR)/$(SODIR)
# cygwin specifics
ifeq ($(ISWINDOWS),true)
	CYGTARGETDIR=$(TRDIR)/bin
ifeq ($(APPNAME),$(MODNAME))
	CYGTARGET=cyg$(APPNAME).dll
else
	CYGTARGET=cyg$(APPNAME)_$(MODNAME).dll
endif
else
	LDFLAGS+= -shared
endif
else
# target is an executable
# executable file name
ifeq ($(APPNAME),$(MODNAME))
	TARGET=$(APPNAME)$(BINEXT)
else
	TARGET=$(APPNAME)_$(MODNAME)$(BINEXT)
endif
# executable file goes in bin subdir of build dir.
	TARGETDIR=$(TRDIR)/bin
endif

# target full path
TARGETFILE=$(TARGETDIR)/$(TARGET)

# LDFLAGS permit to get the created .so that are not MODTYPE library.
# this variable must be evaluated at the use time because at declaration time, the dependencies are not generated yet.
INCLUDE_PROJ_MODS=$(patsubst $(APPNAME)_%,%,$(filter $(PROJECT_MODS),$(sort $(ABS_INCLUDE_LIBS))))

LDFLAGS+=$(foreach mod,$(USEMOD),-L$(TRDIR)/$(SODIR) $(if $(wildcard $(TRDIR)/$(SODIR)/lib$(APPNAME)_$(mod).$(SOEXT)),-l$(APPNAME)_$(mod),)$(if $(wildcard $(TRDIR)/$(SODIR)/lib$(mod).*),-l$(mod),))
LDFLAGS+=$(foreach mod,$(INCLUDE_PROJ_MODS),-L$(TRDIR)/$(SODIR))
CFLAGS+=$(patsubst %,-I$(TRDIR)/include,$(INCLUDE_PROJ_MODS))

# add paths to used modules' headers & libs.
CFLAGS+=$(patsubst %,-I$(PRJROOT)/%/include,$(INCLUDE_PROJ_MODS)) 
LDFLAGS+=$(patsubst %,-l%,$(LINKLIB))

INCLUDE_LIBS_EXT=$(filter-out $(PROJECT_MODS),$(sort $(ABS_INCLUDE_LIBS))) $(LINKLIB)

INCLUDE_LIBS_EXT_LOOKING_PATHS=$(sort $(foreach modExt,$(INCLUDE_LIBS_EXT),$(_module_$(modExt)_dir) $(_app_$(modExt)_dir)))
INCLUDE_LIBS_EXT_CPATHS=$(foreach path,$(INCLUDE_LIBS_EXT_LOOKING_PATHS),$(wildcard $(path)/include))
CFLAGS+=$(foreach extPath,$(INCLUDE_LIBS_EXT_CPATHS),-I$(extPath))
INCLUDE_LIBS_EXT_LDPATHS+=$(foreach path,$(INCLUDE_LIBS_EXT_LOOKING_PATHS),$(filter-out %/library.json,$(wildcard $(path)/lib*)))
LDFLAGS+=$(foreach extPath,$(INCLUDE_LIBS_EXT_LDPATHS),-L$(extPath))

# if advanced dependency management is disable, all the external libs are used for the compilation.
ifeq ($(ADV_DEPENDS_MANAGEMENT),false)
EXT_LIBS_WITHOUT_JSON=$(foreach lib,$(ALL_LIBS_LOADED),$(if $(wildcard $(_app_$(lib)_dir)/library.json),,$(_app_$(lib)_dir)))
CFLAGS+=$(foreach extPath,$(EXT_LIBS_WITHOUT_JSON),-I$(extPath)/include)
EXT_LIBS_WITHOUT_JSON_LDPATHS+=$(foreach path,$(EXT_LIBS_WITHOUT_JSON),$(filter-out %/library.json,$(wildcard $(path)/lib*)))
LDFLAGS+=$(foreach extPath,$(EXT_LIBS_WITHOUT_JSON_LDPATHS),-L$(extPath))
endif

# library dir list (to be forwarded to LD_LIBRARY_PATH env var before running the app)
LDLIBP=$(subst $(_space_),:,$(patsubst -%,,$(patsubst -L%,%,$(filter -L%,$(LDFLAGS)))))
RUNPATH:=$(TRDIR)/bin$(subst $(_space_),,$(patsubst %,:$(EXTLIBDIR)/%/bin,$(USELIB))):$(PATH)

LDRUNP?=$$ORIGIN/../lib

# ---------------------------------------------------------------------
# Compilation flags by compilation modes
# ---------------------------------------------------------------------
## DEBUGCFLAGS: additional compiler option to set on debug mode only (default: empty)
IDENTCFLAGS:=-D__APPNAME__='$(APPNAME)' -D__MODNAME__='$(MODNAME)'
ifeq ($(MODE),debug)
# debugging symbols, no optimisation, optionnal flags for debug mode
CFLAGS+=-g -D_$(APPNAME)_$(MODNAME)_debug -D_abs_trace_debug $(IDENTCFLAGS) $(DEBUGCFLAGS)
else
# some optimisation, no debbugging symbol, optionnal flags for release mode
## RELEASECFLAGS: additional compiler option to set on release mode only (default: -O3)
RELEASECFLAGS?=-O3
CFLAGS+=-D_$(APPNAME)_$(MODNAME)_release $(IDENTCFLAGS) $(RELEASECFLAGS)
endif


## - ACTIVATE_SANITIZER: activate the compiler sanitizer
##     - true: address sanitizer (leak memory detector)
##     - thread: thread sanitizer (data race detector). Incompatible with address sanitizer
## To disable the leak detection on sources compiled with address sanitizer, use the environment variable asan_options=detect_leaks=0
## /!\ Must not be used to compile production binaries.
## 

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
define gen-json-cc
endef
else
define gen-json-cc
@echo '{"directory":"$(MODROOT)","command":"$(CC) $(CFLAGS) -c $< -o $@","file":"$<","output":"$@"},' > $@.json
endef
endif

ifneq ($(filter clang%,$(CPPC)),)
EXTRA_CXXFLAGS+=-MJ $@.json
define gen-json-cppc
endef
else
define gen-json-cppc
@echo '{"directory":"$(MODROOT)","command":"$(CPPC) $(CXXFLAGS) $(CFLAGS) -c $< -o $@","file":"$<","output":"$@"},' > $@.json
endef
endif

define cc-command
@$(ABS_PRINT_info) "Compiling $< ..."
@mkdir -p $(@D)
@echo `date --rfc-3339 s`"> $(CC) $(CFLAGS) $(EXTRA_CFLAGS) -c $< -o $@" >> $(BUILDLOG)
$(gen-json-cc)
@$(CC) $(CFLAGS) $(EXTRA_CFLAGS) -c $< -o $@ \
   && ( cp $@.d $@.d.tmp ; sed -e 's/#.*//' -e 's/^[^:]*: *//' -e 's/ *\\$$//' -e '/^$$/ d' -e 's/$$/ :/' $@.d.tmp >> $@.d ; rm $@.d.tmp ) \
   || ( $(ABS_PRINT_error) "Failed: CFLAGS=$(CFLAGS)" ; exit 1 )
endef

define cxx-command
@$(ABS_PRINT_info) "Compiling $< ..."
@mkdir -p $(@D)
@echo `date --rfc-3339 s`"> $(CPPC) $(CXXFLAGS) $(CFLAGS) $(EXTRA_CXXFLAGS) -c $< -o $@" >> $(BUILDLOG)
$(gen-json-cppc)
@$(CPPC) $(CXXFLAGS) $(CFLAGS) $(EXTRA_CXXFLAGS) -c $< -o $@ \
   && ( cp $@.d $@.d.tmp ; sed -e 's/#.*//' -e 's/^[^:]*: *//' -e 's/ *\\$$//' -e '/^$$/ d' -e 's/$$/ :/' $@.d.tmp >> $@.d ; rm $@.d.tmp ) 
endef

ifneq ($(ISWINDOWS),true)
define ld-command
@$(ABS_PRINT_info) "Linking $@ ..."
@mkdir -p $(TARGETDIR)
@echo `date --rfc-3339 s`"> LD_RUN_PATH='$(LDRUNP)' LD_LIBRARY_PATH=$(LDLIBP) $(LD) -o $@ $(OBJS) $(LDFLAGS)" >> $(BUILDLOG)
@LD_RUN_PATH='$(LDRUNP)' LD_LIBRARY_PATH=$(LDLIBP) $(LD) -o $@ $(OBJS) $(LDFLAGS)
endef
else
define ld-command
@$(ABS_PRINT_info) "Linking $@ ..."
@mkdir -p $(TARGETDIR) $(CYGTARGETDIR)
@echo `date --rfc-3339 s`"> $(LD) -shared -o $(CYGTARGETDIR)/$(CYGTARGET) -Wl,--out-implib=$@ -Wl,--export-all-symbols -Wl,--enable-auto-import -Wl,--whole-archive $(OBJS) -Wl,--no-whole-archive $(LDFLAGS)" >> $(BUILDLOG)
@$(LD) -shared -o $(CYGTARGETDIR)/$(CYGTARGET) -Wl,--out-implib=$@\
	-Wl,--export-all-symbols -Wl,--enable-auto-import -Wl,--whole-archive $(OBJS) -Wl,--no-whole-archive $(LDFLAGS)
endef
endif
