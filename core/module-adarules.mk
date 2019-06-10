
ADAFLAGS+=$(filter -I%,$(CFLAGS))

ADAC?=gnatmake
ADAOBJS+=$(patsubst src/%.adb,$(OBJDIR)/%.o,$(filter-out $(patsubst %,src/%,$(DISABLE_SRC)),$(filter %.adb,$(SRCFILES))))

OBJS+=$(ADAOBJS)

# ada files compilation
$(OBJDIR)/%.o: src/%.adb
	@$(ABS_PRINT_info) "Compiling $< ..."
	@mkdir -p $(@D)
	@echo `date --rfc-3339 s`"> $(ADAC) $(ADAFLAGS) -c $< -D $(@D)" >> $(TRDIR)/build.log
	@$(ADAC) $(CFLAGS) -c $< -D $(@D) || ( $(ABS_PRINT_error) "Failed: ADAFLAGS=$(ADAFLAGS)" ; exit 1 )
