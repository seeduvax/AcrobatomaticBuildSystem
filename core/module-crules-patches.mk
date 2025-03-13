# This makefile permit to apply patches from patches directory.
# The patches must follow the same hierarchy than sources or includes.
# The patches must have same name than sources to patches with .patch extension.
# For example, 
#     - to patch subdir/source.cpp, the patch must be patches/subdir/source.cpp.patch
#     - to patch include/$(APPNAME)/$(MODNAME)/subdir2/head.hpp, the patch must be patches/subdir2/head.hpp.patch
# The patches are applied from top level of src and include.
# The patches can only be applied on files from EXT_MODSRC_DIR

ifneq ($(DISABLE_PATCHES),true)
ifneq ($(wildcard patches),)
ALL_PATCHES=$(shell find patches/ -type f)
ALL_PATCHED=$(patsubst patches/%.patch,$(OBJDIR)/%.patched,$(ALL_PATCHES))

$(OBJS): $(ALL_PATCHED)

# patches for source archive files
$(OBJDIR)/%.patched: patches/%.patch $(TR_MOD_INCLUDE_DIR)/%
	@$(ABS_PRINT_info) "Patching $* in $(TR_MOD_INCLUDE_DIR)"
	@mkdir -p $(@D)
	@patch -p0 -d $(TR_MOD_INCLUDE_DIR) < $<
	@touch $@

$(OBJDIR)/%.patched: patches/%.patch $(EXT_MODSRC_DIR)/%
	@$(ABS_PRINT_info) "Patching $* in $(EXT_MODSRC_DIR)"
	@mkdir -p $(@D)
	@patch -p0 -d $(EXT_MODSRC_DIR) < $<
	@touch $@

endif
endif