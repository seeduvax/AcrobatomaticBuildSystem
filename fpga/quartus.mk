QUARTUS_BINDIR?=/opt/intelFPGA_lite/20.1/quartus/bin

QUARTUS_COMPIL=$(QUARTUS_BINDIR)/quartus_sh --flow compile
QUARTUS_CPF=$(QUARTUS_BINDIR)/quartus_cpf
TOP_LEVEL_ENTITY?=$(APPNAME)_$(MODNAME)


VHDLASSIGN=$(patsubst %,set_global_assignment -name VHDL_FILE  $(PRJROOT)/$(MODNAME)/%\n,$(VHDLSRC))
MODEDEPVHDL=$(foreach mod,$(USEMOD),$(wildcard $(PRJROOT)/$(mod)/src/*.vh*))
VHDLASSIGN+=$(patsubst %,set_global_assignment -name VHDL_FILE  %\n,$(MODEDEPVHDL))

$(OBJDIR)/%.qpf: module.cfg
	@$(ABS_PRINT_info) "Generating quartus II project files..."
	@mkdir -p $(@D)
	@printf 'DATE = "'`date`'"\nQUARTUS_VERSION = "16.0.0"\nPROJECT_REVISION = "$(APPNAME)_$(MODNAME)-$(VERSION)"\n' > $@

$(OBJDIR)/%.qsf: $(QUARTUS_QSF_TEMPLATE)
	@cp $< $@
	@echo 'set_global_assignment -name PROJECT_CREATION_TIME_DATE "'`date`'"' >> $@

$(OBJDIR)/srcfiles.qsf:
	@mkdir -p $(@D)
	@echo 'set_global_assignment -name TOP_LEVEL_ENTITY "$(TOP_LEVEL_ENTITY)"' > $@
	@printf '$(VHDLASSIGN)' >> $@

#	@for file in $(VHDLSRC);\
#	do echo "set_global_assignment -name VHDL_FILE $(CURDIR)/$$file" >> $@ ;\
#	done

$(OBJDIR)/clocks.sdc: $(QUARTUS_SDC)
	@mkdir -p $(@D)
	@cp $< $@

$(OBJDIR)/$(TOP_LEVEL_ENTITY).v: src/$(TOP_LEVEL_ENTITY).v
	@mkdir -p $(@D)
	@cp $< $@

$(OBJDIR)/%.sof: $(OBJDIR)/%.qpf $(OBJDIR)/%.qsf $(OBJDIR)/$(TOP_LEVEL_ENTITY).v $(OBJDIR)/srcfiles.qsf
	@mkdir -p $(@D)
	@cd $(@D) ; $(QUARTUS_COMPIL) $(MODNAME)


.PRECIOUS: $(OBJDIR)/%.sof

$(TRDIR)/lib/%.rbf: $(OBJDIR)/%.sof
	@mkdir -p $(@D)
	@$(QUARTUS_CPF) -c $(QUARTUS_CPFFLAGS) $< $@

##  rbf: create fpga configuration raw binary file
rbf: $(TRDIR)/lib/$(MODNAME).rbf

.PHONY: toplevel
##  toplevel: create top level integration file
toplevel:
	@sed -e 's/__top_level_entity__/$(TOP_LEVEL_ENTITY)/g' $(TOP_LEVEL_TEMPLATE) > src/$(TOP_LEVEL_ENTITY).v
