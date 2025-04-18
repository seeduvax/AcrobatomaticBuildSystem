# ---------------------------------------------------------------------
# Main entry point for Rust compilations
# ---------------------------------------------------------------------

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
	@cd $(RUST_GENERATION_DIR) && wget https://static.rust-lang.org/dist/$(RUST_INSTALL_SRC_NAME) -O $@.tmp
	@mv $@.tmp $@

$(RUST_GENERATION_DIR)/.extracted: $(RUST_INSTALL_SRC)
	@$(ABS_PRINT_info) "Extraction of $<"
	@mkdir -p $(RUST_EXTRACT_DIR)
	@cd $(RUST_GENERATION_DIR) && tar -xf $< -C $(RUST_EXTRACT_DIR) --strip-components=1
	@touch $@

$(RUST_GENERATION_IMPORT_MK): $(RUST_GENERATION_DIR)/.extracted
	@mkdir -p $(@D)/lib $(@D)/bin
	@cp -r $(RUST_EXTRACT_DIR)/rust-std-$(RUST_INSTALL_SRC_ARCH)/lib/rustlib/$(RUST_INSTALL_SRC_ARCH)/lib/* $(@D)/lib
	@cp -r $(RUST_EXTRACT_DIR)/rustc/lib/* $(@D)/lib
	@cp -r $(RUST_EXTRACT_DIR)/rustc/bin/* $(@D)/bin
	@cp -r $(RUST_EXTRACT_DIR)/cargo/bin/* $(@D)/bin
	@echo "# generated: ABS-$(__ABS_VERSION__) $(USER)@"`hostname`" "`$(TRACE_DATE_CMD)` > $@.tmp
	@printf '_app_rust_dir:=$$(dir $$(lastword $$(MAKEFILE_LIST)))\n\n' >> $@.tmp
	@printf '$$(eval $$(call extlib_import_template,rust,$(RUST_VERSION),))\n' >> $@.tmp
	@printf 'RUST_BIN_DIR=$$(_app_rust_dir)/bin/\n' >> $@.tmp
	@printf 'RUST_LIB_DIR=$$(_app_rust_dir)/lib/\n' >> $@.tmp
	@mv $@.tmp $@

$(RUST_GENERATION_DEST_ARCHIVE): $(RUST_GENERATION_IMPORT_MK)
	@$(ABS_PRINT_info) "Creation of $@"
	@tar -czf $@ -C $(RUST_GENERATION_DIR) rust-$(RUST_VERSION)

#
# This job generate the archive containing rustc and its libraries
# to be able to run generated binary from a system without rust installed.
#
newRustPackage: $(RUST_GENERATION_DEST_ARCHIVE)



