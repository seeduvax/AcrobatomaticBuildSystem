
ifeq ($(MODE),debug)
RUSTFLAGS+=-g
endif
ifeq ($(MODE),release)
RUSTFLAGS+=-O
endif

# CRATE Type for doc generation or test execution
ONE_CRATETYPE=$(if $(filter bin,$(CRATETYPE)),bin,lib)

# Initialize rustc edition
# prefer use RUST_EDITION than EDITION
ifneq ($(RUST_EDITION),)
RUSTFLAGS+=--edition $(RUST_EDITION)
else
ifneq ($(EDITION),)
RUSTFLAGS+=--edition $(EDITION)
endif
endif

# Initialize name of rustc entry file
ifeq ($(filter bin,$(CRATETYPE)),)
ENTRYFILENAME?=lib.rs
RUSTFLAGS=-C prefer-dynamic
else
ENTRYFILENAME?=main.rs
endif

DOCTARGET:=$(TRDIR)/rustdoc/$(APPNAME)_$(MODNAME)

# RUST_BIN_DIR => directory of rust binaries
RUST_BIN_DIR?=
RUST_LIB_DIR?=
RUSTC=rustc

RUSTDOC=rustdoc

RUSTLIBDIR=$(TRDIR)/lib

RUSTLIBS=$(foreach MOD,$(USEMOD),--extern $(MOD)=$(RUSTLIBDIR)/librust_$(APPNAME)_$(MOD).so)

INCLUDE_MODS_EXT=$(filter-out $(PROJECT_INC_MODS),$(sort $(ABS_INCLUDE_MODS))) $(LINKLIB)
INCLUDE_MODS_EXT_LOOKING_PATHS=$(sort $(foreach modExt,$(INCLUDE_MODS_EXT),$(_module_$(modExt)_dir) $(_app_$(modExt)_dir)))
INCLUDE_MODS_EXT_LDPATHS+=$(foreach path,$(INCLUDE_MODS_EXT_LOOKING_PATHS),$(filter-out %/library.json,$(wildcard $(path)/lib*)))
LDFLAGS+=$(foreach extPath,$(INCLUDE_MODS_EXT_LDPATHS),-L$(extPath))
# library dir list (to be forwarded to LD_LIBRARY_PATH env var before running the app)
LDLIBP=$(TRDIR)/lib:$(RUST_LIB_DIR):$(subst $(_space_),:,$(patsubst -%,,$(patsubst -L%,%,$(filter -L%,$(LDFLAGS)))))

RUSTFLAGS+=-L$(TRDIR)/lib
RUSTFLAGS+=$(patsubst %/import.mk,-L%/lib,$(EXTLIBMAKES))

# ---------------------------------------------------------------------
# Run & debug rules
# ---------------------------------------------------------------------
RUNTIME_PROLOG?=:
RUNTIME_EPILOG?=:
ifneq ($(filter bin,$(CRATETYPE)),)
# run application
run:: all
	@$(ABS_PRINT_info) "Starting $(RUST_TARGET_FILE_BIN) $(RUNARGS)"
	@$(RUNTIME_PROLOG)
	@LD_LIBRARY_PATH=$(LDLIBP) $(RUNTIME_ENV) $(RUST_TARGET_FILE_BIN) $(RUNARGS) \
      || $(ABS_PRINT_error) "Run failed: $(RUST_TARGET_FILE_BIN) $(RUNARGS)"
	@$(RUNTIME_EPILOG)

# run application with gdb
debug:: $(RUST_TARGET_FILE_BIN)
	@printf "define runapp\nrun $(RUNARGS)\nend\n" > cmd.gdb
	@$(ABS_PRINT_info) "Use runapp command to launch app from gdb"
	@LD_LIBRARY_PATH=$(LDLIBP) $(RUNTIME_ENV) gdb $(RUST_TARGET_FILE_BIN) -x cmd.gdb
	@rm cmd.gdb

# print eclipse setup
.PHONY:	edebug
edebug:
	@echo "**** Eclipse debugger setup : ****"
	@echo
	@printf "Application:\t\t"
	@echo "$(patsubst $(PRJROOT)/%,%,$(RUST_TARGET_FILE_BIN))"
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

define rust_compile
@$(ABS_PRINT_info) "Rust compile $(1) from src/$(ENTRYFILENAME)"
@mkdir -p $(@D)
@LD_LIBRARY_PATH=$(LDLIBP) $(RUST_BIN_DIR)$(RUSTC) --crate-type $(1) $(RUSTFLAGS) $(RUSTLIBS) src/$(ENTRYFILENAME) -o $@ && \
	$(ABS_PRINT_info) "Rust crate built: $@" || ($(ABS_PRINT_error) "Rust cannot build crate: $@" && false)
endef

# ---------------------------------------------------------------------
# Build rule
# The differents targets must not be construct at the same time because they used the same temporary file.
# ---------------------------------------------------------------------
$(RUST_TARGET_FILE_BIN): $(RUSTSRCFILES)
	$(call rust_compile,bin)

$(RUST_TARGET_FILE_RLIB): $(RUSTSRCFILES)
	$(call rust_compile,rlib)

$(RUST_TARGET_FILE_SO): $(RUSTSRCFILES) $(OBJDIR)/rust_target_file_rlib.done
	$(call rust_compile,cdylib)

$(RUST_TARGET_FILE_RUST_SO): $(RUSTSRCFILES) $(OBJDIR)/rust_target_file_cdylib.done
	$(call rust_compile,dylib)
	
# Files to avoid compiling the libs at the same time
$(OBJDIR)/rust_target_file_rlib.done: $(if $(filter rlib,$(CRATETYPE)),$(RUST_TARGET_FILE_RLIB),)
	@touch $@

$(OBJDIR)/rust_target_file_cdylib.done: $(if $(filter rlib,$(CRATETYPE)),$(RUST_TARGET_FILE_SO),)
	@touch $@

# ---------------------------------------------------------------------
# Doc rule
# ---------------------------------------------------------------------
doc:
	@$(ABS_PRINT_info) "Generating Rust docs for $(APPNAME)_$(MODNAME)"
	@mkdir -p $(DOCTARGET)
	$(RUSTDOC) --crate-name $(MODNAME) --crate-type $(ONE_CRATETYPE) $(RUSTLIBS) src/$(ENTRYFILENAME) -o $(DOCTARGET)

# ---------------------------------------------------------------------
# Include test module
# ---------------------------------------------------------------------
ifneq ($(INCTESTS),)
include $(ABSROOT)/core/rust/module-testrust.mk
endif