# ---------------------------------------------------------------------
# Common Rust variables and dependency management
# ---------------------------------------------------------------------
ifeq ($(ISWINDOWS),true)
SOEXT=.dll
EXEEXT=.exe
else
SOEXT=.so
EXEEXT=
endif

# Initialize name of rustc entry file
ifeq ($(ENTRYFILENAME),)
ENTRYFILENAME=lib
endif

# Initialize type of crate
ifeq ($(CRATETYPE),)
CRATETYPE=bin
endif

# Initialize rustc edition
ifneq ($(EDITION),)
RUSTFLAGS+=--edition $(EDITION)
endif

ifeq ($(CRATETYPE),dylib)
TARGETDIR:=$(TRDIR)/lib
ifeq ($(APPNAME),$(MODNAME))
TARGET=lib$(APPNAME)$(SOEXT)
else
TARGET=lib$(APPNAME)_$(MODNAME)$(SOEXT)
endif
else ifeq ($(CRATETYPE),rlib)
TARGETDIR:=$(TRDIR)/lib
ifeq ($(APPNAME),$(MODNAME))
TARGET=lib$(APPNAME).rlib
else
TARGET=lib$(APPNAME)_$(MODNAME).rlib
endif
else
ENTRYFILENAME=main
TARGETDIR:=$(TRDIR)/bin
ifeq ($(APPNAME),$(MODNAME))
TARGET=$(APPNAME)$(EXEEXT)
else
TARGET=$(APPNAME)_$(MODNAME)$(EXEEXT)
endif
endif

TARGETFILE:=$(TARGETDIR)/$(TARGET)
DOCTARGET:=$(TRDIR)/rustdoc/$(APPNAME)_$(MODNAME)

RUSTSRCFILES:=$(filter %.rs,$(SRCFILES))

RUSTC=rustc

RUSTDOC=rustdoc

RUSTLIBDIR=$(TRDIR)/lib

RUSTLIBS=$(foreach MOD,$(USEMOD),--extern $(MOD)=$(RUSTLIBDIR)/lib$(APPNAME)_$(MOD).rlib)

RUSTFLAGS+=-L$(TRDIR)/lib
RUSTFLAGS+=$(patsubst %/import.mk,-L%/lib,$(EXTLIBMAKES))

ifeq ($(MODE),debug)
RUSTFLAGS+=-g
endif
ifeq ($(MODE),release)
RUSTFLAGS+=-O
endif


# ---------------------------------------------------------------------
# Run & debug rules
# ---------------------------------------------------------------------
RUNTIME_PROLOG?=:
RUNTIME_EPILOG?=:
ifeq ($(CRATETYPE),bin)
# run application
run:: all
	@$(ABS_PRINT_info) "Starting $(TARGETFILE) $(RUNARGS)"
	@$(RUNTIME_PROLOG)
	@LD_LIBRARY_PATH=$(LDLIBP) $(RUNTIME_ENV) $(TARGETFILE) $(RUNARGS) \
      || $(ABS_PRINT_error) "Run failed: $(TARGETFILE) $(RUNARGS)"
	@$(RUNTIME_EPILOG)

# run application with gdb
debug:: $(TARGETFILE)
	@printf "define runapp\nrun $(RUNARGS)\nend\n" > cmd.gdb
	@printf "\e[1;4mUse runapp command to launch app from gdb\n\e[37;37;0m"
	@LD_LIBRARY_PATH=$(LDLIBP) $(RUNTIME_ENV) gdb $(TARGETFILE) -x cmd.gdb
	@rm cmd.gdb

# print eclipse setup
.PHONY:	edebug
edebug:
	@echo "**** Eclipse debugger setup : ****"
	@echo
	@printf "Application:\t\t"
	@echo "$(patsubst $(PRJROOT)/%,%,$(TARGETFILE))"
	@printf "Arguments:\t\t"
	@echo $(RUNARGS)
	@echo
	@echo "* Environment (replace native) :"
	@echo
	@printf "LD_LIBRARY_PATH\t"
	@echo "$(subst $(eval) ,:,$(foreach entry,$(subst :, ,$(LDLIBP)),$(patsubst $(PRJROOT)/%,%,$(entry))))"
else
# don't run a library !
run:: all
	$(ABS_PRINT_error) "won't run a library !"

debug:: all
	$(ABS_PRINT_error) "won't debug a library !"
endif


# ---------------------------------------------------------------------
# Build rule
# ---------------------------------------------------------------------
$(TARGETFILE): $(RUSTSRCFILES)
	@$(ABS_PRINT_info) "Rust compile $(CRATETYPE) from src/$(ENTRYFILENAME).rs"
	@mkdir -p $(@D)
	@$(RUSTC) --crate-type $(CRATETYPE) $(RUSTFLAGS) src/$(ENTRYFILENAME).rs -o $@ && \
        $(ABS_PRINT_info) "Rust crate built: $@"

all-impl:: $(TARGETFILE) 


# ---------------------------------------------------------------------
# Doc rule
# ---------------------------------------------------------------------
doc:
	@$(ABS_PRINT_info) "Generating Rust docs for $(APPNAME)_$(MODNAME)"
	mkdir -p $(DOCTARGET)
	$(RUSTDOC) --crate-name $(MODNAME) --crate-type $(CRATETYPE) $(RUSTLIBS) src/$(ENTRYFILENAME).rs -o $(DOCTARGET)


# ---------------------------------------------------------------------
# Include test module
# ---------------------------------------------------------------------
ifneq ($(INCTESTS),)
include $(ABSROOT)/core/module-testrust.mk
endif

