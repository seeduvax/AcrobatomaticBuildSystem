$(info Rust test module loaded)

TTARGETFILE=$(RUST_TARGET_FILE_BIN)_test
ifneq ($(filter rlib,$(ONE_CRATETYPE)),)
TTARGETFILE=$(RUST_TARGET_FILE_RLIB)_test
endif

# ---------------------------------------------------------------------
# Run & debug rules
# ---------------------------------------------------------------------
RUNTIME_PROLOG?=:
RUNTIME_EPILOG?=:
# run application with gdb
debugtest:: testbuild
	@printf "define runtests\nrun $(RUNARGS)\nend\n" > cmd.gdb
	@printf "\e[1;4mUse runtests command to launch tests from gdb\n\e[37;37;0m"
	@LD_LIBRARY_PATH=$(LDLIBP) $(RUNTIME_ENV) gdb $(TTARGETFILE) -x cmd.gdb
	@rm cmd.gdb

testbuild:: all
	@$(ABS_PRINT_info) "Rust compile tests from src/$(ENTRYFILENAME)"
	@mkdir -p $(TRDIR)/bin
	@LD_LIBRARY_PATH=$(LDLIBP) $(RUST_BIN_DIR)$(RUSTC) --crate-type $(ONE_CRATETYPE) --test $(RUSTFLAGS) $(RUSTLIBS) src/$(ENTRYFILENAME) -o $(TTARGETFILE) && \
	$(ABS_PRINT_info) "Rust tests for crate built: $(TARGETFILE)"

test:: testbuild
	@LD_LIBRARY_PATH=$(LDLIBP) $(TTARGETFILE) --nocapture

valgrindtest:: testbuild
	valgrind $(TTARGETFILE)

