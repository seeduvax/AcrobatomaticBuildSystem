all:

include ../app.cfg
include module.cfg

MODNAME?=$(notdir $(abspath .))


# add dependencies between module to avoid compile module at the same time.
$(PRJOBJDIR)/$(MODNAME)/moddeps.mk:
	@$(ABS_PRINT_info) "Generating $(MODNAME) module dependency file."
	@mkdir -p $(@D)
	@echo "# "`date` > $@.tmp
	@echo "\n\
"'ifeq ($$(_module_$(APPNAME)_$(MODNAME)_dir),)'"\n\
include $(patsubst %,$(PRJOBJDIR)/%/moddeps.mk,$(USEMOD))\n\
\n\
ABS_INCLUDE_MODS+=$(MODNAME)\n\
_module_$(MODNAME)_dir=$(PRJROOT)/$(MODNAME)\n\
_module_$(APPNAME)_$(MODNAME)_dir=$(TRDIR)\n\
_module_$(APPNAME)_$(MODNAME)_depends="'$$(sort $(LINKLIB) $(patsubst %,$(APPNAME)_%,$(USEMOD)) $(foreach dep,$(LINKLIB) $(patsubst %,$(APPNAME)_%,$(USEMOD)),$$(_module_$(dep)_depends)))'"\n\
\n\
\$$(PRJOBJDIR)/\$$(MODNAME)/.depready: \$$(patsubst %,\$$(PRJOBJDIR)/%/.done,$(USEMOD))\n\
\n\
\$$(PRJOBJDIR)/\$$(MODNAME)/.done: "'$$(call find,\$$(PRJROOT)/\$$(MODNAME),*)'"\n\
\n" >> $@.tmp
	@ALLMODS="$(sort $(USEMOD))"; DEPENDSMODS=; for modName in $$ALLMODS; do\
		echo "\$$(PRJOBJDIR)/$$modName/.done: \$$(patsubst %,\$$(PRJOBJDIR)/%/.done,$$DEPENDSMODS)\n" >> $@.tmp; \
		DEPENDSMODS="$$DEPENDSMODS $$modName"; \
done
	@printf "\nendif\n" >> $@.tmp
	@mv $@.tmp $@

all: $(PRJOBJDIR)/$(MODNAME)/moddeps.mk
