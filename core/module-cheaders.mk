# A way to publish public headers from "imported" modules, without having to
# move files to please buildscripts.
TARGETFILES+=$(patsubst %,$(TR_MOD_INCLUDE_DIR)/%,$(PUB_H))
# headers publication rule
$(TR_MOD_INCLUDE_DIR)/%.h: src/%.h
	@$(ABS_PRINT_info) "Publishing $< ..."
	@mkdir -p $(@D)
	@cp $< $@

$(TR_MOD_INCLUDE_DIR)/%.h: h/%.h
	@$(ABS_PRINT_info) "Publishing $< ..."
	@mkdir -p $(@D)
	@cp $< $@

$(TR_MOD_INCLUDE_DIR)/%.h: $(EXT_MODSRC_DIR)/%.h
	@$(ABS_PRINT_info) "Publishing $< ..."
	@mkdir -p $(@D)
	@cp $< $@
