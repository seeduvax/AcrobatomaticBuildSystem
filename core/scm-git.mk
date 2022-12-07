## --------------------------------------------------------------------
## Configuration management services
## --------------------------------------------------------------------

ABS_SCM_TYPE:=git
ABS_GIT_DESCR:=$(shell git describe --always --dirty)
REVISION:=$(ABS_GIT_DESCR)
GIT_REPOSITORY?=origin

ifeq ($(ABS_GIT_DESCR),$(APPNAME)-$(VMAJOR).$(VMEDIUM).$(VMINOR))
WORKSPACE_IS_TAG:=1
REVISION:=$(REVISION)-$(shell git rev-parse --short $(ABS_GIT_DESCR))
else
WORKSPACE_IS_TAG:=0
endif

define abs_scm_tag
@git tag -a $(APPNAME)-$(TAG_VERSION) $(TAG_REVISION) -m "#$(VISSUE) $(M)" && \
 git push $(GIT_REPOSITORY) $(APPNAME)-$(TAG_VERSION) || (\
 git tag -d $(APPNAME)-$(TAG_VERSION) ;\
 $(ABS_PRINT_error) "Tag push to $(GIT_REPOSITORY) failed. Tag removed." ;\
 exit 1 )
endef

define abs_scm_commit
@git commit -a -m "$1" && ( git push $(GIT_REPOSITORY) || (\
 $(ABS_PRINT_error) "Changes commit succeed but push to $(GIT_REPOSITORY)) failed." ;\
 $(ABS_PRINT_error) "Push shall be invoked again with the following command:" ;\
 $(ABS_PRINT_error) "    git push $(GIT_REPOSITORY)" ;\
 exit 1) )
endef

define abs_scm_branch
git checkout -b $(APPNAME)-$(NEW_BRANCH) && \
 sed -i 's/^VERSION=.*$$/VERSION=$(NEW_BRANCH).0/g;s/VPARENT=.*$$/VPARENT=$(TAG_VERSION)/g;s/VISSUE=.*$$/VISSUE=$(I)/g' app.cfg && \
 git commit app.cfg -m "#$(I) [open branch $(NEW_BRANCH) from $(TAG_VERSION)] $(M)" && \
 ( git push --set-upstream $(GIT_REPOSITORY) $(APPNAME)-$(NEW_BRANCH) \
   ||($(ABS_PRINT_error) "New branch and version update commit succeed but push to $(GIT_REPOSITORY) failed." ;\
   $(ABS_PRINT_error) "Push shall be invoked again with the following command:" ;\
   $(ABS_PRINT_error) "    git push --set-upstream $(GIT_REPOSITORY) $(APPNAME)-$(NEW_BRANCH)" ;\
   exit 1) )
endef

define abs_scm_file_revision
git log --pretty=format:"%h" -1 $1
endef

$(BUILDROOT)/scm/file-list.txt:
	@$(ABS_PRINT_info) "Generating file index for $(APPNAME)-$(VERSION)"
	@mkdir -p $(@D)
	@git ls-tree $(APPNAME)-$(VERSION) -r --full-tree | while read mode type sign path ; do echo "$$path % "`git log --pretty=format:"%h" -1 $(APPNAME)-$(VERSION) $(PRJROOT)/$$path`" % $$sign" >> $@ ; done

$(BUILDROOT)/scm/diff.txt:
	@$(ABS_PRINT_info) "Generating diff index for $(APPNAME) from $(VPARENT) to $(VERSION)"
	@mkdir -p $(@D)
	@git diff $(APPNAME)-$(VPARENT) $(APPNAME)-$(VERSION) --name-status | while read op path ; do echo "$$op % $$path" >> $@ ; done

$(BUILDROOT)/scm/log.xml:
	@$(ABS_PRINT_info) "Generating log index for $(APPNAME) from $(VPARENT) to $(VERSION)"
	@mkdir -p $(@D)
	@echo '<?xml version="1.0" encoding="utf-8"?>' > $@
	@echo "<log>"  >> $@
	@git log $(APPNAME)-$(VPARENT)..$(APPNAME)-$(VERSION) --pretty=format:'<logentry revision="%h"><author>%an</author><date>%ad</date><msg>%B</msg></logentry>' | sed -e 's/&/&amp;/g' >> $@
	@echo "</log>" >> $@
## Targets:
## - scm-release: build configuration management indexes
scm-release:: $(patsubst %,$(BUILDROOT)/scm/%, file-list.txt diff.txt log.xml)

# install generic hook to enable plugin and stacking
ifneq ($(wildcard $(PRJROOT)/.git/hooks),)

$(PRJROOT)/.git/hooks/%: $(ABSROOT)/core/git-dloop-hook.sh
	@mkdir -p $@.d
	@cp $^ $@
	@chmod +x $@

ABS_GIT_HOOKS:=$(patsubst %.sample,%,$(wildcard $(PRJROOT)/.git/hooks/*.sample)) $(PRJROOT)/.git/hooks/post-commit

$(PRJROOT)/app.cfg: $(ABS_GIT_HOOKS)

## - cleangithooks: reset git hooks.
cleangithooks:
	for hook in $(ABS_GIT_HOOKS); do rm -rf $$hook $$hook.d ; done

endif
