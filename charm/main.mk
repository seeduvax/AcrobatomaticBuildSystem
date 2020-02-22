ifneq ($(ABS_INC_GUARD_CHARM),1)
ABS_INC_GUARD_CHARM:=1
## --------------------------------------------------------------------
## Charm: Change request management
## --------------------------------------------------------------------
## Variables:
##   - CREDITOR: Change request file editor
CREDITOR?=vim

CRDIR:=$(PRJROOT)/_cr/src/
##   - CRID: change request to work with.
ifeq ($(MAKECMDGOALS),crnew)
$(info New CR title:)
CRTITLE:=$(shell read title ; echo $$title)
CRID=$(word 1,$(shell echo "$(USER)@$(HOSTNAME):$(CRTITLE)" | sha256sum))
else
CRID=$(word 1,$(shell cat $(BUILDROOT)/charm-sel.cr))
endif

## Targets:
##   - create new change request
crnew:
	@mkdir -p $(CRDIR)
	@printf "{cr \%id=$(CRID)\n{title $(CRTITLE)}\n}\n" > $(CRDIR)/$(CRID).cr
	@echo "$(CRID)" > $(BUILDROOT)/charm-sel.cr

##   - cred: edit selected change request
cred:
	$(CREDITOR) $(CRDIR)/$(CRID).cr

##   - crls list change requests (current branch only)
crls:
	@ls $(CRDIR)

##   - crsel <CR Id> select change request
ifeq ($(word 1,$(MAKECMDGOALS)),crsel)
CRID:=$(patsubst $(CRDIR)/%.cr,%,$(wildcard $(CRDIR)/$(word 2,$(MAKECMDGOALS))*.cr)) 
crsel:
	@mkdir -p $(BUILDROOT)
	@echo "$(CRID)" > $(BUILDROOT)/charm-sel.cr

$(word 2,$(MAKECMDGOAL)):

endif

##   - crcat: show selected cr
crcat:
	@cat $(CRDIR)/$(CRID).cr

endif
