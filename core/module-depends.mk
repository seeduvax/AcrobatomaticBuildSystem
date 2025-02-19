all:

include ../app.cfg
include module.cfg

MODNAME?=$(notdir $(abspath .))


# add dependencies between modules to avoid compile module at the same time.
# .done must depends of other .done to propagate the multithread dependency.
$(PRJOBJDIR)/$(MODNAME)/moddeps.mk:
	@$(ABS_PRINT_info) "Generating $(MODNAME) module dependency file."
	@mkdir -p $(@D)
	@echo "# "`date` > $@.tmp
	@printf 'ifeq ($$(_module_$(APPNAME)_$(MODNAME)_dir),)\n'\
'include $$(patsubst %%,$$(PRJOBJDIR)/%%/moddeps.mk,$(USEMOD))\n\n'\
'ABS_INCLUDE_MODS+=$(MODNAME)\n'\
'_module_$(MODNAME)_dir=$$(PRJROOT)/$(MODNAME)\n'\
'_module_$(APPNAME)_$(MODNAME)_dir=$$(TRDIR)\n'\
'_module_$(APPNAME)_$(MODNAME)_depends=$$(sort $(LINKLIB) $(INCLUDE_MODS) $(patsubst %,$(APPNAME)_%,$(USEMOD)) $(foreach dep,$(LINKLIB) $(INCLUDE_MODS) $(patsubst %,$(APPNAME)_%,$(USEMOD)),$$(_module_$(dep)_depends)))\n\n'\
'$$(PRJOBJDIR)/$(MODNAME)/.depready: $(patsubst %,$$(PRJOBJDIR)/%/.done,$(USEMOD) $(TESTUSEMOD))\n\n'\
'$$(PRJOBJDIR)/$(MODNAME)/.done: $$(call find,$$(PRJROOT)/$(MODNAME),*)\n\n' >> $@.tmp
	@printf '$$(PRJOBJDIR)/$(MODNAME)/.done: $$(patsubst %%,$$(PRJOBJDIR)/%%/.done,$(sort $(USEMOD) $(TESTUSEMOD)))\n' >> $@.tmp
	@printf "\nendif\n" >> $@.tmp
	@mv $@.tmp $@

all: $(PRJOBJDIR)/$(MODNAME)/moddeps.mk
