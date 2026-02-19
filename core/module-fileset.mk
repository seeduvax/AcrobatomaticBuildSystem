## 
## -----------------------------------------------------------------------
## Fileset module specific features
## -----------------------------------------------------------------------
## Variables:
##    - FILESET_OUTPUT_DIR: relative directory where to copy files (default is empty)
FILESET_OUTPUT_DIR?=
FILESET_ABS_OUTPUT=$(TRDIR)$(if $(FILESET_OUTPUT_DIR),/$(FILESET_OUTPUT_DIR))
FILESET_SRCFILES?=$(SRCFILES)
TARGETFILES+=$(patsubst src/%,$(FILESET_ABS_OUTPUT)/%,$(FILESET_SRCFILES))

$(TRDIR)/bin/%: src/bin/%
	@$(ABS_PRINT_info) "Publishing $< to $(patsubst $(TRDIR)/%,%,$@)..."
	@mkdir -p $(@D)
	@cp $(COPYOPTIONS) $< $@
	@$(call executeFiltering, $<, $@)
	@chmod a+x $@

$(FILESET_ABS_OUTPUT)/%: src/% 
	@$(ABS_PRINT_info) "Publishing $< to $(patsubst $(TRDIR)/%,%,$@)..."
	@mkdir -p $(@D)
	@cp $(COPYOPTIONS) $< $@
	@$(call executeFiltering, $<, $@)

## Specific target behavior for fileset: 
## - run <script_name> [RUNARGS="<arg> [<arg>]*]": run script. The script to
##   run this way should have its source file as src/bin/<script_name>
ifeq ($(word 1,$(MAKECMDGOALS)),run)
CMDTORUN=$(word 2,$(MAKECMDGOALS))
ifneq ($(CMDTORUN),)
run:: $(TRDIR)/bin/$(CMDTORUN) $(TARGETFILES)
	@$(ABS_PRINT_info) "Launching: $(CMDTORUN) $(RUNARGS)"
	@PATH="$(RUNPATH)" LD_LIBRARY_PATH="$(LDLIBP)" $< $(RUNARGS)

$(CMDTORUN): $(TRDIR)/bin/$(CMDTORUN)
	@echo

endif
endif

include $(ABSROOT)/core/module-crules-vars.mk

ifneq ($(INCTESTS),)
include $(ABSROOT)/core/module-test.mk
endif
