all:

include ../app.cfg
include module.cfg

_MODNAME:=$(notdir $(abspath .))
ifneq ($(filter-out $(_MODNAME),$(MODNAME)),)
$(info $(shell $(ABS_PRINT_warning) "The name of the module '$(MODNAME)' differ from the module directory name '$(_MODNAME)'"))
endif
MODNAME?=$(_MODNAME)

# PROJECT_INC_MODS permit to filter project modules in INCLUDE_MODS
PROJECT_INC_MODS:=$(patsubst $(PRJROOT)/%/module.cfg,$(APPNAME)_%,$(wildcard $(PRJROOT)/*/module.cfg))
# INCLUDE_MODS permit to add dependency between mods but without doing link between generated libraries.
NEEDED_PROJ_MODS=$(sort $(USEMOD) $(TESTUSEMOD) $(patsubst $(APPNAME)_%,%,$(filter $(PROJECT_INC_MODS),$(INCLUDE_MODS))))

# add dependencies between modules to avoid compile module at the same time.
# .done must depends of other .done to propagate the multithread dependency.
# the variable _depends will contains libs needed by the module. If the archive name is same than .so, the name lib$(dep) will be used instead of $(dep)
# The externals libs EXTLIBMAKES must be done before launching compilation of dependences.
# ultimate wildcard to eliminate files with space
# add dependence between testmod, to test the modules in the order of dependences. (only use in app level)
$(PRJOBJDIR)/$(MODNAME)/moddeps.mk:
	@$(ABS_PRINT_info) "Generating $(MODNAME) module dependency file."
	@mkdir -p $(@D)
	@echo "# "`date` > $@.tmp
	@printf 'ifeq ($$(_module_$(APPNAME)_$(MODNAME)_dir),)\n'\
'include $$(patsubst %%,$$(PRJOBJDIR)/%%/moddeps.mk,$(NEEDED_PROJ_MODS))\n\n'\
'_module_$(APPNAME)_$(MODNAME)_dir=$$(TRDIR)\n'\
'_module_$(APPNAME)_$(MODNAME)_depends=$$(sort $$(call getLibrariesNameFromLinklib,$(LINKLIB)) $(INCLUDE_MODS) $(patsubst %,$(APPNAME)_%,$(USEMOD)))\n\n'\
'_module_$(APPNAME)_$(MODNAME)_done_depends=$$(patsubst %%,$$(PRJOBJDIR)/%%/.done,$(NEEDED_PROJ_MODS))\n\n'\
'$$(PRJOBJDIR)/$(MODNAME)/.depready: $$(_module_$(APPNAME)_$(MODNAME)_done_depends)\n\n'\
'$$(PRJOBJDIR)/$(MODNAME)/.done: $$(wildcard $$(foreach toLook,etc src include module.cfg local.cfg,$$(call find,$$(PRJROOT)/$(MODNAME)/$$(toLook),*)))\n\n'\
'$$(PRJOBJDIR)/$(MODNAME)/.done: $$(_module_$(APPNAME)_$(MODNAME)_done_depends)\n\n'\
'$$(PRJOBJDIR)/$(MODNAME)/.testdone: $$(PRJOBJDIR)/$(MODNAME)/.done\n'\
'$$(PRJOBJDIR)/$(MODNAME)/.testdone: $$(wildcard $$(foreach toLook,test module.cfg local.cfg,$$(call find,$$(PRJROOT)/$(MODNAME)/$$(toLook),*)))\n\n'\
'testmod.$(MODNAME): $$(patsubst %%,testmod.%%,$(NEEDED_PROJ_MODS))\n\n'\
'endif\n' >> $@.tmp
	@mv $@.tmp $@

all: $(PRJOBJDIR)/$(MODNAME)/moddeps.mk
	@:
