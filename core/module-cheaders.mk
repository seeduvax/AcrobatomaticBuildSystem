# A way to publish public headers from "imported" modules, without having to
# move files to please buildscripts.
PUBLISHED_HEADERS=$(patsubst %,$(TRDIR)/include/$(APPNAME)/$(MODNAME)/%,$(PUB_H))
# headers publication rule
$(TRDIR)/include/$(APPNAME)/$(MODNAME)/%.h: src/%.h
	@$(ABS_PRINT_info) "Publishing $^ ..."
	@mkdir -p $(@D)
	@cp $^ $@

$(TRDIR)/include/$(APPNAME)/$(MODNAME)/%.h: h/%.h
	@$(ABS_PRINT_info) "Publishing $^ ..."
	@mkdir -p $(@D)
	@cp $^ $@
