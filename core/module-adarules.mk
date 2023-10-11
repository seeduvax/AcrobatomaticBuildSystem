
ADAFLAGS?=$(CFLAGS)

ADAC?=$(CC)
ADAOBJS+=$(patsubst src/%.adb,$(OBJDIR)/%.o,$(filter-out $(patsubst %,src/%,$(DISABLE_SRC)),$(filter %.adb,$(SRCFILES))))

OBJS+=$(ADAOBJS)

# ada files compilation
$(OBJDIR)/%.o: src/%.adb
	@$(ABS_PRINT_info) "Compiling ada $< ..."
	@mkdir -p $(@D)
	@echo `$(TRACE_DATE_CMD)`"> $(ADAC) $(ADAFLAGS) -c $< -D $(@D)" >> $(BUILDLOG)
	@$(ADAC) $(ADAFLAGS) -c $< -o $@ || ( $(ABS_PRINT_error) "Failed: ADAFLAGS=$(ADAFLAGS)" ; exit 1 )

# generated ada files compilation
$(OBJDIR)/%.o: $(OBJDIR)/%.adb
	@$(ABS_PRINT_info) "Compiling generated ada $< ..."
	@mkdir -p $(@D)
	@echo `$(TRACE_DATE_CMD)`"> $(ADAC) $(ADAFLAGS) -c $< -D $(@D)" >> $(BUILDLOG)
	@$(ADAC) $(ADAFLAGS) -c $< -o $@ || ( $(ABS_PRINT_error) "Failed: ADAFLAGS=$(ADAFLAGS)" ; exit 1 )
