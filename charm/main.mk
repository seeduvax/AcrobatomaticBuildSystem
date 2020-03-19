ifneq ($(ABS_INC_GUARD_CHARM),1)
ABS_INC_GUARD_CHARM:=1
## --------------------------------------------------------------------
## Charm: Change request management
## --------------------------------------------------------------------
## Variables:
##   - CREDITOR: Change request file editor
CREDITOR?=vim
DATE=$(shell date --rfc-3339=seconds)
CRSRCDIR:=$(PRJROOT)/_charm/src
CRWORKDIR:=$(BUILDROOT)/charm

include $(CRWORKDIR)/vars.mk
$(CRWORKDIR)/vars.mk:
	@mkdir -p $(CRWORKDIR)
	@echo "### generated $(DATE) for $(APPNAME)-$(VMAJOR).$(VMEDIUM)"
	@echo "CR_BRANCH_TRACKING:="$(word 1,$(shell echo '$(APPNAME)-$(VMAJOR).$(VMEDIUM)' | sha256sum)) > $@
	@echo "CRID:=$$(CR_BRANCH_TRACKING)" >> $@

##   - CRID: change request to work with.
ifeq ($(MAKECMDGOALS),crnew)
$(info New CR title:)
CRTITLE:=$(shell read title ; echo $$title)
CRID:=$(word 1,$(shell echo "$(USER)@$(HOSTNAME):$(CRTITLE)" | sha256sum))
endif


# ----------------------------------
# Change Request creation.
# cf element set to null is an indicator of no commit done with issue.
# Is used to define if an issue can be moved to another branch.
define cr_create_file
	@mkdir -p $(CRSRCDIR)
	@printf '<?xml version="1.0" encoding="utf-8"?>\n<cr id="$1" state="open">\n<title>$2</title>\n<reporter>$(USER)</reporter>\n<creation>$(DATE)</creation>\n<description></description>\n<links>\n<link name="parent">$3</link>\n</links>\n<cf v="null"/>\n</cr>\n' > $(CRSRCDIR)/$1.cr
endef


$(CRSRCDIR)/$(CR_BRANCH_TRACKING).cr:
	$(call cr_create_file,$(CR_BRANCH_TRACKING),Release $(APPNAME) $(VMAJOR).$(VMEDIUM))

## Targets:
##   - create new change request
crnew: $(CRSRCDIR)/$(CR_BRANCH_TRACKING).cr
	$(call cr_create_file,$(CRID),$(CRTITLE),$(CR_BRANCH_TRACKING))
	@sed -i 's!</links>!<link name="child">$(CRID)</link>\n</links>!g' $(CRSRCDIR)/$(CR_BRANCH_TRACKING).cr
	@sed -i 's/CRID:=.*$$/CRID:=$(CRID)/g' $(CRWORKDIR)/vars.mk

##   - cred: edit selected change request
cred:
	$(CREDITOR) $(CRSRCDIR)/$(CRID).cr

##   - crls list change requests (current branch only)
crls:
	@xsltproc --path $(CRSRCDIR) $(ABSROOT)/charm/ls-txt.xslt $(CRSRCDIR)/$(CR_BRANCH_TRACKING).cr

##   - crsel <CR Id> select change request
ifeq ($(word 1,$(MAKECMDGOALS)),crsel)
CRID:=$(patsubst $(CRSRCDIR)/%.cr,%,$(wildcard $(CRSRCDIR)/$(word 2,$(MAKECMDGOALS))*.cr))
crsel:
	@sed -i 's/CRID:=.*$$/CRID:=$(CRID)/g' $(CRWORKDIR)/vars.mk

$(word 2,$(MAKECMDGOALS)):

endif

##   - crcat: show selected cr
crcat:
	@xsltproc --path $(CRSRCDIR) $(ABSROOT)/charm/cat-txt.xslt $(CRSRCDIR)/$(CRID).cr

endif

ci:
	@fgrep -c 'state="close' $(CRSRCDIR)/$(CRID).cr > /dev/null && { echo "Current CR is closed..." ; exit 1 ;} || :
	@sed -i 's/state=".*"/state="working"/g' $(CRSRCDIR)/$(CRID).cr
	@sed -i 's!<cf .*/>!<cf v="$(USER) $(DATE)/>!g' $(CRSRCDIR)/$(CRID).cr

# exemple de mise à jour d'un compteur dans un fichier XML avec xmlstarlet
# xmlstarlet ed -L -u /cr/ch[1] -x 'number(/cr/ch[1])+1' 10.cr.xml

# .........................................................
# HTML rendering of CRs
CRHTMLS:=$(patsubst $(CRSRCDIR)/%.cr, $(CRWORKDIR)/www/%.html, $(wildcard $(CRSRCDIR)/*.cr))

$(CRWORKDIR)/www/%.html: $(CRSRCDIR)/%.cr
	@mkdir -p $(@D)
	@xsltproc --path $(CRSRCDIR) $(ABSROOT)/charm/cr2html.xslt $^ > $@

##   - crbro: browse selected cr
crbro: $(CRHTMLS)
	@$(BROWSER) $(CRWORKDIR)/www/$(CRID).html

crbrowse: crbro

