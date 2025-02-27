## 
## --------------------------------------------------------------------------
## Configuration management services
## --------------------------------------------------------------------------
##
## Variables
##  - BRANCH_VERSION: current branch identifier
BRANCH_VERSION:=$(VMAJOR).$(VMEDIUM)
##  - TAG_VERSION: current version identifier to be used for next tagging
TAG_VERSION:=$(BRANCH_VERSION).$(VMINOR)
##  - NEW_VERSION: next version  identifier after tagging.
NEW_VERSION:=$(BRANCH_VERSION).$(shell expr $(VMINOR) + 1)
##
##
## Targets:
##  - tag M="<msg>": create tag
##      <msg>: tag comment message
ifeq ($(M),)
tag:
	@$(ABS_PRINT_error) "Can't tag, comment message is missing."
	@$(ABS_PRINT_error) '    make tag M="<msg>"'
else
tag:
	@$(ABS_PRINT_info) "Tagging $(APPNAME) $(TAG_VERSION) ..."
	$(abs_scm_tag)
	@sed -i -e s/^VERSION=.*$$/VERSION=$(NEW_VERSION)/g app.cfg
	$(call abs_scm_commit,$(VISSUE) [tag switch] $(M))
	@$(ABS_PRINT_info) "# Tag set: $(APPNAME) $(TAG_VERSION)"
endif
##  - branch <X.Y> I=<issue> M="<msg>": create branch <APPNAME>-X.Y
##      <issue>: new branch tracking issue reference.
##      <msg>: branch creation comment message
ifeq ($(word 1,$(MAKECMDGOALS)),branch)
NEW_BRANCH=$(word 2,$(MAKECMDGOALS))
ifeq ($(NEW_BRANCH),)
branch:
	@$(ABS_PRINT_error) "Can't create branch, new branch spec is missing"
	@$(ABS_PRINT_error) "    make branch <X.Y> I=<issue> M='<msg>'"
else
$(NEW_BRANCH):
	@:
ifeq ($(I),)
branch:
	@$(ABS_PRINT_error) "Can't create branch $(APPNAME)-$(NEW_BRANCH), missing tracking issue."
	@$(ABS_PRINT_error) "    make branch <X.Y> I=<issue> M='<msg>'"
else ifeq ($(M),)
branch:
	@$(ABS_PRINT_error) "Can't create branch $(APPNAME)-$(NEW_BRANCH), missing comment message."
	@$(ABS_PRINT_error) "    make branch <X.Y> I=<issue> M='<msg>'"
else
branch:
	@$(ABS_PRINT_info) "Creating branch $(APPNAME)-$(NEW_BRANCH) from $(APPNAME)-$(VERSION)..."
	$(call abs_scm_branch)
endif # check param I and M
endif # check NEW_BRANCH
endif # branch target
