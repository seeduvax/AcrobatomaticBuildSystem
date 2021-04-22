FPGA_EXT_PATH:=$(dir $(lastword $(MAKEFILE_LIST)))
VHDLC?=ghdl

VHDLSRC:=$(filter %.vhd,$(SRCFILES)) $(filter %.vhdl,$(SRCFILES))
OBJHDL:=$(patsubst src/%.vhdl,$(OBJDIR)/sim/%.o,$(filter %.vhdl,$(VHDLSRC))) \
		$(patsubst src/%.vhd,$(OBJDIR)/sim/%.o,$(filter %.vhd,$(VHDLSRC)))

ifeq ($(BOARD),de10nano)
include $(FPGA_EXT_PATH)/de10nano/main.mk
include $(FPGA_EXT_PATH)/quartus.mk
endif


define HDLCOMP
	@$(ABS_PRINT_info) "Compiling HDL $<..."
	@mkdir -p $(@D)
	@$(VHDLC) -a --workdir=$(@D) --ieee=synopsys $<
endef

$(OBJDIR)/sim/%.o: src/%.vhdl
	$(HDLCOMP)

$(OBJDIR)/sim/%.o: src/%.vhd
	$(HDLCOMP)

$(OBJDIR)/sim/sim_%.o: test/%.vhdl $(OBJHDL)
	$(HDLCOMP)

$(OBJDIR)/sim/sim_%.o: test/%.vhdl $(OBJHDL)
	$(HDLCOMP)

$(OBJDIR)/sim/sim_%: $(OBJDIR)/sim/sim_%.o
	@$(ABS_PRINT_info) "Building HDL simulation $(@F)..."
	@mkdir -p $(@D)
	@$(VHDLC) -e --ieee=synopsys --workdir=$(@D) -Wl,-lgnat -Wl,-o$@ $(patsubst sim_%,%,$(@F))
$(OBJDIR)/sim/sim_%.ghw: $(OBJDIR)/sim/sim_%
	@$(ABS_PRINT_info) "Running HDL simulation $(<F)..."
	@$< --stop-time=20ms --wave=$@

ifeq ($(word 1,$(MAKECMDGOALS)),viewsim)
SIMNAME:=$(word 2,$(MAKECMDGOALS))

$(SIMNAME):
	@:

SIMRESFILE:=$(OBJDIR)/sim/sim_$(SIMNAME).ghw

viewsim: $(SIMRESFILE)
	gtkwave $(SIMRESFILE)

endif

test:: $(patsubst test/%.vhdl,$(OBJDIR)/sim/sim_%.ghw,$(wildcard test/*.vhdl)) \
       $(patsubst test/%.vhd,$(OBJDIR)/sim/sim_%.ghw,$(wildcard test/*.vhd))

