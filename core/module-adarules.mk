
ADAFLAGS?=$(CFLAGS)

ADAC?=$(CC)
ADAOBJS+=$(patsubst src/%.adb,$(OBJDIR)/%.o,$(filter-out $(patsubst %,src/%,$(DISABLE_SRC)),$(filter %.adb,$(SRCFILES))))

OBJS+=$(ADAOBJS)

# ada files compilation
$(OBJDIR)/%.o: src/%.adb
	@$(ABS_PRINT_info) "Compiling  KKK $< ..."
	@mkdir -p $(@D)
	@echo `date --rfc-3339 s`"> $(ADAC) $(ADAFLAGS) -c $< -D $(@D)" >> $(TRDIR)/build.log
	@$(ADAC) $(ADAFLAGS) -c $< -o $@ || ( $(ABS_PRINT_error) "Failed: ADAFLAGS=$(ADAFLAGS)" ; exit 1 )
