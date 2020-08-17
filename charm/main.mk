## --------------------------------------------------------------------
## Charm: Change request management
## --------------------------------------------------------------------

# install git hooks
ifneq ($(ABS_INC_GUARD_CHARM),1)
ifeq ($(ABS_SCM_TYPE),git)

$(PRJROOT)/.git/hooks/%: $(ABSROOT)/charm/git_hooks/%
	@$(ABS_PRINT_info) "Installing charm git git hook $(patsubst $(PRJROOT)/.git/hooks/%,%,$@)."
	@cp $^ $@
	@chmod +x $@

SCM_HOOKS:=$(patsubst $(ABSROOT)/charm/git_hooks/%,$(PRJROOT)/.git/hooks/%,$(wildcard $(ABSROOT)/charm/git_hooks/*))

all: $(SCM_HOOKS)

define cr_commit
	@git add "$1"
	@git add "$(CRSRCDIR)/$(CR_BRANCH_TRACKING).cr"
	@git commit --no-verify -m "issue management"
endef

endif


ifneq ($(filter cr%,$(word 1,$(MAKECMDGOALS))),)
ABS_INC_GUARD_CHARM:=1
## Variables:
##   - CREDITOR: Change request file editor
CREDITOR?=vim
DATE=$(shell date --rfc-3339=seconds)
CRSRCDIR:=$(PRJROOT)/_charm/src
CRWORKDIR:=$(BUILDROOT)/charm


SRCINDEXHTML:=$(word 1,$(wildcard $(CRSRCDIR)/index.html) $(ABSROOT)/charm/index.html)
SRCCSS:=$(word 1,$(wildcard $(CRSRCDIR)/style.css) $(ABSROOT)/charm/style.css)


#WXDB:=wxdb-0.1.0d
#WXDBDOM=net.eduvax
#NDUSELIB+=$(WXDB)
#WXDBJAR:=$(NDEXTLIBDIR)/$(WXDB)/lib/$(WXDBDOM).$(WXDB).jar


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
##   - crnew: create new change request
crnew: $(CRSRCDIR)/$(CR_BRANCH_TRACKING).cr
	$(call cr_create_file,$(CRID),$(CRTITLE),$(CR_BRANCH_TRACKING))
	@sed -i 's!</links>!<link name="child">$(CRID)</link>\n</links>!g' $(CRSRCDIR)/$(CR_BRANCH_TRACKING).cr
	@sed -i 's/CRID:=.*$$/CRID:=$(CR_BRANCH_TRACKING)/g' $(CRWORKDIR)/vars.mk
	$(call cr_commit,$(CRSRCDIR)/$(CRID).cr)
	@sed -i 's/CRID:=.*$$/CRID:=$(CRID)/g' $(CRWORKDIR)/vars.mk

##   - cred: edit selected change request
ifeq ($(word 1,$(MAKECMDGOALS)),cred)
JAVACMD?=java
HEMLVERSION?=1.0.2
HEMLJAR?=$(NDNA_EXTLIBDIR)/heml-$(HEMLVERSION).jar
HEMLCMD?=$(JAVACMD) -jar $(call absGetPath,$(HEMLJAR))
ifneq ($(word 2,$(MAKECMDGOALS)),)
CRID:=$(patsubst $(CRSRCDIR)/%.cr,%,$(wildcard $(CRSRCDIR)/$(word 2,$(MAKECMDGOALS))*.cr))

$(word 2,$(MAKECMDGOALS)):

endif
endif
cred: $(HEMLJAR)
	@xsltproc --path $(CRSRCDIR) $(ABSROOT)/charm/edit-heml.xslt $(CRSRCDIR)/$(CRID).cr > $(CRWORKDIR)/edit.heml
	@$(CREDITOR) $(CRWORKDIR)/edit.heml && \
	$(HEMLCMD) -in $(CRWORKDIR)/edit.heml -out $(CRSRCDIR)/$(CRID).cr

##   - crls: list change requests (current branch only)
crls:
	@xsltproc --path $(CRSRCDIR) $(ABSROOT)/charm/ls-txt.xslt $(CRSRCDIR)/$(CR_BRANCH_TRACKING).cr

##   - crsel: <CR Id> select change request
ifeq ($(word 1,$(MAKECMDGOALS)),crsel)
CRID:=$(patsubst $(CRSRCDIR)/%.cr,%,$(wildcard $(CRSRCDIR)/$(word 2,$(MAKECMDGOALS))*.cr))
crsel:
	@sed -i 's/CRID:=.*$$/CRID:=$(CRID)/g' $(CRWORKDIR)/vars.mk

$(word 2,$(MAKECMDGOALS)):
	@:

endif

##   - crcat: show selected cr
ifeq ($(word 1,$(MAKECMDGOALS)),crcat)
ifneq ($(word 2,$(MAKECMDGOALS)),)
CRID:=$(patsubst $(CRSRCDIR)/%.cr,%,$(wildcard $(CRSRCDIR)/$(word 2,$(MAKECMDGOALS))*.cr))

$(word 2,$(MAKECMDGOALS)):

endif
endif
crcat:
	@xsltproc --path $(CRSRCDIR) $(ABSROOT)/charm/cat-txt.xslt $(CRSRCDIR)/$(CRID).cr


# exemple de mise à jour d'un compteur dans un fichier XML avec xmlstarlet
# xmlstarlet ed -L -u /cr/ch[1] -x 'number(/cr/ch[1])+1' 10.cr.xml

# .........................................................
# HTML rendering of CRs
CRHTMLS:=$(patsubst $(CRSRCDIR)/%.cr, $(CRWORKDIR)/www/%.html, $(wildcard $(CRSRCDIR)/*.cr))

$(CRWORKDIR)/www/%.html: $(CRSRCDIR)/%.cr
	@mkdir -p $(@D)
	@xsltproc --path $(CRSRCDIR) $(ABSROOT)/charm/cr2html.xslt $^ > $@

$(CRWORKDIR)/www/index.html: $(SRCINDEXHTML) $(SRCCSS)
	@$(ABS_PRINT_info) "Updating web resources..."
	@mkdir -p $(@D)
	@cp $(SRCINDEXHTML) $(SRCCSS) $(@D)
	@cp -r $(NDEXTLIBDIR)/$(WXDB)/www/js $(@D)/js


##   - crbro: browse selected cr
crbro: $(CRWORKDIR)/www/index.html
	@java -jar $(WXDBJAR) -d ./src -w $(CRWORKDIR)/www & pid=$$! ; \
	$(BROWSER) http://localhost:8888/?oid=$(CRID).cr ; kill $$pid

crbrowse: crbro


endif
endif
