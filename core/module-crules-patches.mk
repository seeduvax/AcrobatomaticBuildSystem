PATCHED_SRC_DIR?=$(ARCHSRC_SRC_DIRECTORY)
PATCHED_OBJ_TYPE?=.o

ifneq ($(wildcard patches),)
ALL_PATCHES=$(shell find patches/ -type f)

ALL_PATCHED=$(patsubst patches/%.patch,$(OBJDIR)/%.patched,$(ALL_PATCHES))

$(OBJS): $(ALL_PATCHED)

$(OBJDIR)/%.patched: patches/%.patch $(ARCHSRC_INCLUDE_DIRECTORY)/%
	@$(ABS_PRINT_info) "Patching $*"
	@mkdir -p $(@D)
	patch -p0 -d $(TRDIR) < $<
	@touch $@

$(OBJDIR)/%.patched: patches/%.patch $(ARCHSRC_SRC_DIRECTORY)/%
	@$(ABS_PRINT_info) "Patching $*"
	@mkdir -p $(@D)
	patch -p0 -d $(EXT_SRC_DIR) < $<
	@touch $@

$(OBJDIR)/%.patched: patches/%.patch src/%
	@$(ABS_PRINT_info) "Patching $*"
	@mkdir -p $(@D)
	patch -p0 -d $(EXT_SRC_DIR) < $<
	@touch $@

endif