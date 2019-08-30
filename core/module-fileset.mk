## -----------------------------------------------------------------------
## Fileset module specific features
## -----------------------------------------------------------------------
TARGETFILES=$(patsubst src/%,$(TRDIR)/%,$(SRCFILES))

$(TRDIR)/bin/%: src/bin/%
	@$(ABS_PRINT_info) "Publishing $^..."
	@mkdir -p $(@D)
	@cp $^ $@
	@$(call executeFiltering, $<, $@)
	@chmod a+x $@

$(TRDIR)/%: src/% 
	@$(ABS_PRINT_info) "Publishing $^..."
	@mkdir -p $(@D)
	@cp $^ $@
	@$(call executeFiltering, $<, $@)

all-impl::$(TARGETFILES) etc

## Specific target behavior for fileset: 
## - run <script_name> [RUNARGS="<arg> [<arg>]*]": run script. The script to
##   run this way should have its source file as src/bin/<script_name>
ifeq ($(word 1,$(MAKECMDGOALS)),run)
CMDTORUN=$(word 2,$(MAKECMDGOALS))
ifneq ($(CMDTORUN),)
run:: $(TARGETFILES) $(TRDIR)/bin/$(CMDTORUN)
	@$(ABS_PRINT_info) "Launching: $(CMDTORUN) $(RUNARGS)"
	@export LD_LIBRARY_PATH="$(LDLIBP)" ; \
	$(TRDIR)/bin/$(CMDTORUN) $(RUNARGS)

$(CMDTORUN): $(TRDIR)/bin/$(CMDTORUN)
	@echo

endif
endif

include $(ABSROOT)/core/module-crules-vars.mk
include $(ABSROOT)/core/module-test.mk
