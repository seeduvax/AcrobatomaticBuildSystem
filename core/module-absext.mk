
TARGETFILES=$(patsubst src/%,$(TRDIR)/.abs/%,$(SRCFILES)) $(TRDIR)/.abs/index_$(MODNAME).mk

$(TRDIR)/.abs/index_$(MODNAME).mk:
	@$(ABS_PRINT_info) "Generating ABS extension index..."
	@mkdir -p $(@D)
	@printf '_absext_index_$(APPNAME)_$(MODNAME):=$$(dir $$(lastword $$(MAKEFILE_LIST)))\n' >> $@
	@$(if $(strip $(ABS_EXT_MAP)), printf 'MODULE_TYPES_MAP+=$(patsubst %,$$(_absext_index_$(APPNAME)_$(MODNAME))/%,$(ABS_EXT_MAP))\n' >> $@)

$(TRDIR)/.abs/%: src/%
	@$(ABS_PRINT_info) "Publishing $^..."
	@mkdir -p $(@D)
	@cp $^ $@

all-impl::$(TARGETFILES)
