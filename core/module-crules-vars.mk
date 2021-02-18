# default C flags
CFLAGS+=-Iinclude -fPIC -I$(TRDIR)/include

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
ifeq ($(findstring Win,$(ARCH)),Win)
SOEXT?=dll
SOPFX?=
SODIR?=bin
else
SOEXT?=so
SOPFX?=lib
SODIR?=lib
endif

CC_VERSION:=$(shell $(CC) -dumpversion)


# add extra symbol definition
CFLAGS+= $(patsubst %,-D%,$(DEFINES))

# add coverage flags on coverage target.
ifeq ($(MAKECMDGOALS),coverage)
CFLAGS+=-coverage
LDFLAGS+=-lgcov
endif

# Target definition
ifeq ($(MODTYPE),library) 
# target is a library
# build a shared library
	LDFLAGS+= -shared
# name of shared library file
ifeq ($(APPNAME),$(MODNAME))
	TARGET=$(SOPFX)$(APPNAME).$(SOEXT)
else
	TARGET=$(SOPFX)$(APPNAME)_$(MODNAME).$(SOEXT)
endif
# shared lib goes into lib subdir of build dir.
	TARGETDIR=$(TRDIR)/$(SODIR)
else
# target is an executable
# executable file name
ifeq ($(APPNAME),$(MODNAME))
	TARGET=$(APPNAME)
else
	TARGET=$(APPNAME)_$(MODNAME)
endif
# executable file goes in bin subdir of build dir.
	TARGETDIR=$(TRDIR)/bin
endif
# target full path
TARGETFILE=$(TARGETDIR)/$(TARGET)

# LDFLAGSUSEMOD permit to get the created .so that are not MODTYPE library.
# this variable must be evaluated at the use time because at declaration time, the dependencies are not generated yet.
LDFLAGSUSEMOD=$(foreach mod,$(USEMOD),$(if $(wildcard $(TRDIR)/$(SODIR)/lib$(APPNAME)_$(mod).so),-l$(APPNAME)_$(mod),)$(if $(wildcard $(TRDIR)/$(SODIR)/lib$(mod).*),-l$(mod),))

# add paths to used modules' headers & libs.
CFLAGS+= $(patsubst %,-I$(PRJROOT)/%/include,$(USEMOD)) 
LDFLAGS+= -L$(TRDIR)/$(SODIR) $(LDFLAGSUSEMOD)
LDFLAGS+=$(patsubst %,-l%,$(LINKLIB))
# library dir list (to be forwarded to LD_LIBRARY_PATH env var befor running the app)
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
CFLAGS+= -g -D_$(APPNAME)_$(MODNAME)_debug -D_abs_trace_debug $(IDENTCFLAGS) $(DEBUGCFLAGS)
else
# some optimisation, no debbugging symbol, optionnal flags for release mode
## RELEASECFLAGS: additional compiler option to set on release mode only (default: -O3)
RELEASECFLAGS?=-O3
CFLAGS+= -D_$(APPNAME)_$(MODNAME)_release $(IDENTCFLAGS) $(RELEASECFLAGS)
endif

define cc-command
@$(ABS_PRINT_info) "Compiling $< ..."
@mkdir -p $(@D)
@echo `date --rfc-3339 s`"> $(CC) $(CFLAGS) -c $< -o $@" >> $(TRDIR)/build.log
@$(CC) $(CFLAGS) -MMD -MF $@.d -c $< -o $@ \
   && ( cp $@.d $@.d.tmp ; sed -e 's/#.*//' -e 's/^[^:]*: *//' -e 's/ *\\$$//' -e '/^$$/ d' -e 's/$$/ :/' $@.d.tmp >> $@.d ; rm $@.d.tmp ) \
   || ( $(ABS_PRINT_error) "Failed: CFLAGS=$(CFLAGS)" ; exit 1 )
endef

define cxx-command
@$(ABS_PRINT_info) "Compiling $< ..."
@mkdir -p $(@D)
@echo `date --rfc-3339 s`"> $(CPPC) $(CXXFLAGS) $(CFLAGS) -c $< -o $@" >> $(TRDIR)/build.log 
@$(CPPC) $(CXXFLAGS) $(CFLAGS) -MMD -MF $@.d -c $< -o $@ \
   && ( cp $@.d $@.d.tmp ; sed -e 's/#.*//' -e 's/^[^:]*: *//' -e 's/ *\\$$//' -e '/^$$/ d' -e 's/$$/ :/' $@.d.tmp >> $@.d ; rm $@.d.tmp ) 
endef

define ld-command
@$(ABS_PRINT_info) "Linking $@ ..."
@mkdir -p $(TARGETDIR)
@echo `date --rfc-3339 s`"> LD_RUN_PATH='$(LDRUNP)' LD_LIBRARY_PATH=$(LDLIBP) $(LD) -o $@ $(OBJS) $(LDFLAGS)" >> $(TRDIR)/build.log
@LD_RUN_PATH='$(LDRUNP)' LD_LIBRARY_PATH=$(LDLIBP) $(LD) -o $@ $(OBJS) $(LDFLAGS) 
endef
