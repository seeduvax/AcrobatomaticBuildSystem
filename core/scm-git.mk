## --------------------------------------------------------------------
## Configuration management services
## --------------------------------------------------------------------

ABS_SCM_TYPE:=git
ABS_GIT_DESCR:=$(shell git describe --tags)
REVISION:=$(subst $(APPNAME)-%,%,$(shell git describe --tags))
GIT_REPOSITORY?=origin

ifeq ($(ABS_GIT_DESCR),$(APPNAME)-$(VERSION))
WORKSPACE_IS_TAG:=1
else
WORKSPACE_IS_TAG:=0
 ifneq ($(shell LANG=C git status | grep -c modified),0)
REVISION:=$(REVISION)M
 endif
endif

define abs_scm_tag
@git tag -a $(APPNAME)-$(TAG_VERSION) $(TAG_REVISION) -m "#$(VISSUE) $(M)" && \
 git push $(GIT_REPOSITORY) $(APPNAME)-$(TAG_VERSION)
endef

define abs_scm_commit
@git commit -a -m "$1" && git push --all $(GIT_REPOSITORY)
endef

define abs_scm_branch
@git checkout -b $(NEW_BRANCH) && \
 printf '1,$$s/VERSION=.*\$$/VERSION=$(NEW_BRANCH).0/g\n1,$$s/VPARENT=.*$$/VPARENT=$(TAG_VERSION)/g\n1,$$s/VISSUE=.*$$/VISSUE=$(I)/g\nwq\n' | ed app.cfg && \
 git commit app.cfg -m "#$(I) [open branch $(NEW_BRANCH) from $(TAG_VERSION)] $(M)" && \
 git push --all $(GIT_REPOSITORY)
endef


$(BUILDROOT)/scm/file-list.txt:
	@$(ABS_PRINT_info) "Generating file index for $(APPNAME)-$(VERSION)"
	@mkdir -p $(@D)
	@git ls-tree $(APPNAME)-$(VERSION) -r --full-tree | while read mode type sign path ; do echo "$$path % $$sign" >> $@ ; done

$(BUILDROOT)/scm/diff.txt:
	@$(ABS_PRINT_info) "Generating diff index for $(APPNAME) from $(VPARENT) to-$(VERSION)"
	@mkdir -p $(@D)
	@git diff $(APPNAME)-$(VPARENT) $(APPNAME)-$(VERSION) --name-status | while read op path ; do echo "$$op % $$path" >> $@ ; done

$(BUILDROOT)/scm/log.xml:
	@$(ABS_PRINT_info) "Generating log index for $(APPNAME) from $(VPARENT) to-$(VERSION)"
	@mkdir -p $(@D)
	@echo '<?xml version="1.0" encoding="utf-8"?>' > $@
	@echo "<log>"  >> $@
	@git log $(APPNAME)-$(VPARENT)..$(APPNAME)-$(VERSION) --pretty=format:'<logentry revision="%h"><author>%an</author><date>%ad</date><msg>%s</msg></logentry>' >> $@
	@echo "</log>" >> $@
## Targets:
## - scm-release: build configuration management indexes
scm-release:: $(patsubst %,$(BUILDROOT)/scm/%, file-list.txt diff.txt log.xml)
