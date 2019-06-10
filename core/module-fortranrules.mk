FORTRANFLAGS+=$(filter -I%,$(CFLAGS))
FORTRANC?=gfortran
FORTRANOBJS+=$(patsubst src/%.f,$(OBJDIR)/%.o,$(filter-out $(patsubst %,src/%,$(DISABLE_SRC)),$(filter %.f,$(SRCFILES))))

OBJS+=$(FORTRANOBJS)

define fortranc-command
@$(ABS_PRINT_info) "Compiling $< ..."
@mkdir -p $(@D)
@echo `date --rfc-3339 s`"> $(FORTRANC) $(FORTRANFLAGS) -c $< -D $(@D)" >> $(TRDIR)/build.log
@$(FORTRANC) $(CFLAGS) -c $< -o $@ || ( $(ABS_PRINT_error) "Failed: FORTRANFLAGS=$(FORTRANFLAGS)" ; exit 1 )
endef

# fortran files compilation
$(OBJDIR)/%.o: src/%.f
	$(fortranc-command)

$(OBJDIR)/%.o: src/%.f77
	$(fortranc-command)

$(OBJDIR)/%.o: src/%.f90
	$(fortranc-command)

$(OBJDIR)/%.o: src/%.for
	$(fortranc-command)

$(OBJDIR)/%.o: src/%.F
	$(fortranc-command)

$(OBJDIR)/%.o: src/%.F90
	$(fortranc-command)

