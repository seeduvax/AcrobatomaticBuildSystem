all:

include ../app.cfg
include module.cfg

MODNAME?=$(notdir $(abspath .))


# add dependencies between modules to avoid compile module at the same time.
# .done must depends of other .done to propagate the multithread dependency.
# the variable _depends will contains all libs needed by the module. If the archive name is same than .so, the name lib$(dep) will be used instead of $(dep)
# The externals libs EXTLIBMAKES must be done before launching compilation of dependences.
$(PRJOBJDIR)/$(MODNAME)/moddeps.mk:
	@$(ABS_PRINT_info) "Generating $(MODNAME) module dependency file."
	@mkdir -p $(@D)
	@echo "# "`date` > $@.tmp
	@printf 'ifeq ($$(_module_$(APPNAME)_$(MODNAME)_dir),)\n'\
'include $$(patsubst %%,$$(PRJOBJDIR)/%%/moddeps.mk,$(USEMOD))\n\n'\
'ABS_INCLUDE_MODS+=$$(patsubst %%,$(APPNAME)_%%,$(USEMOD) $(TESTUSEMOD))\n'\
'_module_$(MODNAME)_dir=$$(PRJROOT)/$(MODNAME)\n'\
'_module_$(APPNAME)_$(MODNAME)_dir=$$(TRDIR)\n'\
'_module_$(APPNAME)_$(MODNAME)_depends_raw=$$(sort $(LINKLIB) $(INCLUDE_MODS) $(patsubst %,$(APPNAME)_%,$(USEMOD)) $(foreach dep,$(LINKLIB) $(INCLUDE_MODS) $(patsubst %,$(APPNAME)_%,$(USEMOD)),$$(_module_$(dep)_depends)))\n'\
'_module_$(APPNAME)_$(MODNAME)_depends=$$(foreach dep,$$(_module_$(APPNAME)_$(MODNAME)_depends_raw),$$(if $$(_app_lib$$(dep)_dir),lib$$(dep),$$(dep)))\n\n'\
'_module_$(APPNAME)_$(MODNAME)_done_depends=$$(patsubst %%,$$(PRJOBJDIR)/%%/.done,$(sort $(USEMOD) $(TESTUSEMOD)))\n\n'\
'$$(PRJOBJDIR)/$(MODNAME)/.depready: $$(_module_$(APPNAME)_$(MODNAME)_done_depends)\n\n'\
'$$(PRJOBJDIR)/$(MODNAME)/.done: $$(call find,$$(PRJROOT)/$(MODNAME),*)\n\n' >> $@.tmp
	@printf '$$(PRJOBJDIR)/$(MODNAME)/.done: $$(_module_$(APPNAME)_$(MODNAME)_done_depends)\n' >> $@.tmp
	@printf "\nendif\n" >> $@.tmp
	@mv $@.tmp $@

all: $(PRJOBJDIR)/$(MODNAME)/moddeps.mk
