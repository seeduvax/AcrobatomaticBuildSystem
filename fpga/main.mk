FPGA_EXT_PATH:=$(dir $(lastword $(MAKEFILE_LIST)))
VHDLC?=ghdl

VHDLSRC:=$(filter %.vhd,$(SRCFILES)) $(filter %.vhdl,$(SRCFILES))
OBJHDL:=$(patsubst src/%.vhdl,$(OBJDIR)/%.o,$(filter %.vhdl,$(VHDLSRC))) \
		$(patsubst src/%.vhd,$(OBJDIR)/%.o,$(filter %.vhd,$(VHDLSRC)))
VHDLLIBS:=$(patsubst %,-P$(TRDIR)/obj/%,$(USEMOD))

ifeq ($(BOARD),de10nano)
include $(FPGA_EXT_PATH)/de10nano/main.mk
include $(FPGA_EXT_PATH)/quartus.mk
endif


define HDLCOMP
	@$(ABS_PRINT_info) "Compiling HDL $<..."
	@mkdir -p $(@D)
	@$(VHDLC) -a --work=$(MODNAME) --workdir=$(@D) --ieee=synopsys $(VHDLLIBS) $(VHDLCFLAGS) $<
endef

$(OBJDIR)/%.o: src/%.vhdl
	$(HDLCOMP)

$(OBJDIR)/%.o: src/%.vhd
	$(HDLCOMP)

$(OBJDIR)/sim_%.o: test/%.vhdl $(OBJHDL)
	$(HDLCOMP)

$(OBJDIR)/sim_%.o: test/%.vhdl $(OBJHDL)
	$(HDLCOMP)

$(OBJDIR)/sim_%: $(OBJDIR)/sim_%.o
	@$(ABS_PRINT_info) "Building HDL simulation $(@F)..."
	@mkdir -p $(@D)
	@$(VHDLC) -e --ieee=synopsys --work=$(MODNAME) --workdir=$(@D) $(VHDLLIBS) $(VHDLCFLAGS) -Wl,-lgnat -Wl,-o$@ $(patsubst sim_%,%,$(@F))
$(OBJDIR)/sim_%.ghw: $(OBJDIR)/sim_%
	@$(ABS_PRINT_info) "Running HDL simulation $(<F)..."
	@$< --wave=$@

ifeq ($(word 1,$(MAKECMDGOALS)),viewsim)
SIMNAME:=$(word 2,$(MAKECMDGOALS))

$(SIMNAME):
	@:

SIMRESFILE:=$(OBJDIR)/sim_$(SIMNAME).ghw

viewsim: $(SIMRESFILE)
	gtkwave $(SIMRESFILE)

endif

test:: $(patsubst test/%.vhdl,$(OBJDIR)/sim_%.ghw,$(wildcard test/*.vhdl)) \
       $(patsubst test/%.vhd,$(OBJDIR)/sim_%.ghw,$(wildcard test/*.vhd))

