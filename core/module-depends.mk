include ../app.cfg
include module.cfg

MODNAME?=$(notdir $(abspath .))


$(PRJOBJDIR)/$(MODNAME)/moddeps.mk:
	@$(ABS_PRINT_info) "Generating $(MODNAME) module dependency file."
	@mkdir -p $(@D)
	@echo "# "`date` > $@
	@printf "\n\
"'ifeq ($$(_module_$(APPNAME)_$(MODNAME)_dir),)'"\n\
include $(patsubst %,$(PRJOBJDIR)/%/moddeps.mk,$(USEMOD))\n\
\n\
ABS_INCLUDE_MODS+=$(MODNAME)\n\
_module_$(MODNAME)_dir=$(PRJROOT)/$(MODNAME)\n\
_module_$(APPNAME)_$(MODNAME)_dir=$(TRDIR)\n\
_module_$(APPNAME)_$(MODNAME)_depends=$(LINKLIB) $(patsubst %,$(APPNAME)_%,$(USEMOD))\n\
\n\
$(PRJOBJDIR)/$(MODNAME)/.depready: $(patsubst %,$(PRJOBJDIR)/%/.done,$(USEMOD))\n\
\n\
$(PRJOBJDIR)/$(MODNAME)/.done: "'$$(call find,$(PRJROOT)/$(MODNAME),*)'"\n\
\n\
endif\n" >> $@
