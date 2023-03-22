$(info Rust test module loaded)

TTARGETFILE=$(TARGETFILE)-tests

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
	@$(ABS_PRINT_info) "Rust compile tests from src/$(ENTRYFILENAME).rs"
	@mkdir -p $(@D)
	@$(RUSTC) --edition=$(EDITION) --crate-type $(CRATETYPE) --test $(RUSTFLAGS) src/$(ENTRYFILENAME).rs -o $(TTARGETFILE) && \
        $(ABS_PRINT_info) "Rust tests for crate built: $(TARGETFILE)"

test:: testbuild
	$(TTARGETFILE)

valgrindtest:: testbuild
	valgrind $(TTARGETFILE)

