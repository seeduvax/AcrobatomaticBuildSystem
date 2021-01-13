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
 git push $(GIT_REPOSITORY) $(APPNAME)-$(TAG_VERSION)
endef

define abs_scm_commit
@git commit -a -m "$1" && git push --all $(GIT_REPOSITORY)
endef

define abs_scm_branch
git checkout -b $(APPNAME)-$(NEW_BRANCH) && \
 printf '1,$$s/^VERSION=.*$$/VERSION=$(NEW_BRANCH).0/g\n1,$$s/VPARENT=.*$$/VPARENT=$(TAG_VERSION)/g\n1,$$s/VISSUE=.*$$/VISSUE=$(I)/g\nwq\n' | ed app.cfg && \
 git commit app.cfg -m "#$(I) [open branch $(NEW_BRANCH) from $(TAG_VERSION)] $(M)" && \
 git push --all $(GIT_REPOSITORY)
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
