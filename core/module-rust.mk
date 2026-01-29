## 
## ---------------------------------------------------------------------
## Main entry point for Rust compilations
## ---------------------------------------------------------------------
## Targets:
##  - init: initialize the module by modifying module.cfg
##  - newRustPackage: generate a new ABS package containing rust. 
##    Use RUSTUP_DIST_SERVER to get the url of rust-lang (or default is https://static.rust-lang.org)

include $(ABSROOT)/core/rust/module-rust-vars.mk

ifeq ($(USE_CARGO),true)

include $(ABSROOT)/core/rust/module-rust-cargo.mk

else # ($(USE_CARGO),true)

include $(ABSROOT)/core/rust/module-rust-rustc.mk

endif # ($(USE_CARGO),true)

TARGETFILES+=$(RUST_TARGET_FILES)

# this target will create the archive for rust dynamic loaded libraries.
RUST_GENERATION_DIR=$(OBJDIR)/rust_arch_generation
RUST_INSTALL_SRC_ARCH=x86_64-unknown-linux-gnu
RUST_INSTALL_SRC_NAME=rust-$(RUST_VERSION)-$(RUST_INSTALL_SRC_ARCH).tar.xz
RUST_INSTALL_SRC=$(RUST_GENERATION_DIR)/$(RUST_INSTALL_SRC_NAME)
RUST_EXTRACT_DIR=$(RUST_GENERATION_DIR)/extracted
RUST_GENERATION_IMPORT_MK=$(RUST_GENERATION_DIR)/rust-$(RUST_VERSION)/import.mk
RUST_GENERATION_DEST_ARCHIVE=$(RUST_GENERATION_DIR)/rust-$(RUST_VERSION)_unknown_x86_64.tar.gz

$(RUST_INSTALL_SRC):
	@mkdir -p $(RUST_GENERATION_DIR)
	@cd $(RUST_GENERATION_DIR) && wget $(if $(RUSTUP_DIST_SERVER),$(RUSTUP_DIST_SERVER),https://static.rust-lang.org)/dist/$(RUST_INSTALL_SRC_NAME) -O $@.tmp
	@mv $@.tmp $@

$(RUST_GENERATION_DIR)/.extracted: $(RUST_INSTALL_SRC)
	@$(ABS_PRINT_info) "Extraction of $<"
	@mkdir -p $(RUST_EXTRACT_DIR)
	@cd $(RUST_GENERATION_DIR) && tar -xf $< -C $(RUST_EXTRACT_DIR) --strip-components=1
	@touch $@

$(RUST_GENERATION_IMPORT_MK): $(RUST_GENERATION_DIR)/.extracted
	@$(RUST_EXTRACT_DIR)/install.sh --destdir=$(@D) --prefix= \
		--components=rustc,cargo,rust-docs,rust-std-$(RUST_INSTALL_SRC_ARCH),rust-analysis-$(RUST_INSTALL_SRC_ARCH)
	@echo "# generated: ABS-$(__ABS_VERSION__) $(USER)@"`hostname`" "`$(TRACE_DATE_CMD)` > $@.tmp
	@printf '_app_rust_dir:=$$(dir $$(lastword $$(MAKEFILE_LIST)))\n\n' >> $@.tmp
	@printf '$$(eval $$(call extlib_import_template,rust,$(RUST_VERSION),))\n' >> $@.tmp
	@printf 'RUST_BIN_DIR=$$(_app_rust_dir)/bin/\n' >> $@.tmp
	@printf 'RUST_LIB_DIR=$$(_app_rust_dir)/lib/\n' >> $@.tmp
	@mv $@.tmp $@

$(RUST_GENERATION_DEST_ARCHIVE): $(RUST_GENERATION_IMPORT_MK)
	@$(ABS_PRINT_info) "Creation of $@"
	@tar --exclude=doc --exclude=uninstall.sh -czf $@ -C $(RUST_GENERATION_DIR) rust-$(RUST_VERSION)

# initialize the module for RUST
init:
	@$(ABS_PRINT_info) "Use Cargo ? (Y/n)" && read answer && use_cargo=`test "$$answer" = 'n' && echo 'false' || echo 'true'` && \
		grep -q "^USE_CARGO" module.cfg && sed -i -E "s/USE_CARGO:=.*/USE_CARGO:=$$use_cargo/g" module.cfg || echo "USE_CARGO:=$$use_cargo" >> module.cfg
	@$(ABS_PRINT_info) "Is library ? (Y/n)" && read answer && type=`test "$$answer" = 'n' && echo 'bin' || echo 'lib'` && \
		(grep -q "^CRATETYPE" module.cfg && sed -i -E "s/CRATETYPE:=.*/CRATETYPE:=$$type/g" module.cfg || echo "CRATETYPE:=$$type" >> module.cfg) && \
		test "$$answer" = 'n' && (test -f src/main.rs || echo "fn main() { println!(\"Hello world\"); }" > src/main.rs) || touch src/lib.rs

#
# This job generate the archive containing rustc and its libraries
# to be able to run generated binary from a system without rust installed.
#
newRustPackage: $(RUST_GENERATION_DEST_ARCHIVE)



