ABS_SCM_TYPE:=svn
WORKSPACE_IS_TAG:=$(shell LANG=C svn info | grep "^URL:" | grep -c "/tags/")
REVISION:=$(shell svnversion)
SVNROOT:=$(shell LANG=C svn info | grep "^Repository Root:" | sed -e 's/^Repository Root: //g')
# SVNPRJROOT is the directory where are the tags, branches and trunk directories
SVNPRJROOT?=$(SVNROOT)
SVNURL:=$(shell LANG=C svn info | grep "^URL:" | sed -e 's/^URL: //g')
SVNURLFROM=$(SVNROOT)/tags/$(APPNAME)/$(APPNAME)-$(VPARENT)
SVNURLTO=$(SVNROOT)/tags/$(APPNAME)/$(APPNAME)-$(VERSION)

# backward compability.
TAG_REVISION?=$(SVN_REVISION)
TAG_REVISION?=HEAD

ifneq ($(SVN_PASSWORD),)
SVNFLAGS+=--password '$(SVN_PASSWORD)'
endif

define abs_scm_tag
@svn copy $(SVNFLAGS) $(SVNURL)@$(TAG_REVISION) $(SVNPRJROOT)/tags/$(APPNAME)/$(APPNAME)-$(TAG_VERSION) -m "$(VISSUE) $(M)"
endef

define abs_scm_commit
@svn commit $(SVNFLAGS) -m "$1"
endef

define abs_scm_branch
@svn copy $(SVNFLAGS) $(SVNURL)@$(TAG_REVISION) $(SVNPRJROOT)/branches/$(APPNAME)-$(NEW_BRANCH) -m "$(I) [open branch $(NEW_BRANCH) from $(TAG_VERSION)] $(M)" && \
 svn co $(SVNPRJROOT)/branches/$(APPNAME)-$(NEW_BRANCH) tmp.$(APPNAME)-$(NEW_BRANCH) && \
 cd tmp.$(APPNAME)-$(NEW_BRANCH) && \
 printf '1,$$s/VERSION=.*$$/VERSION=$(NEW_BRANCH).0/g\n1,$$s/VPARENT=.*$$/VPARENT=$(TAG_VERSION)/g\n1,$$s/VISSUE=.*$$/VISSUE=$(I)/g\nwq\n' | ed app.cfg && \
 svn commit $(SVNFLAGS) -m "$(I) [open branch $(NEW_BRANCH) from $(TAG_VERSION)] $(M)" && \
 cd - && \
 rm -rf tmp.$(APPNAME)-$(NEW_BRANCH)
endef

$(BUILDROOT)/scm/file-list.xml:
	@$(ABS_PRINT_info) "Generating file index for $(APPNAME)-$(VERSION)"
	@mkdir -p $(@D)
	@svn $(SVNFLAGS) ls -R --xml $(SVNURLTO) > $@

$(BUILDROOT)/scm/diff.xml:
	@$(ABS_PRINT_info) "Generating diff index for $(APPNAME) from $(VPARENT) to-$(VERSION)"
	@mkdir -p $(@D)
	@svn $(SVNFLAGS) diff --xml --summarize --notice-ancestry --old=$(SVNURLFROM) --new=$(SVNURLTO) | sed -e "s!$(SVNURLFROM)/!!g" > $@

$(BUILDROOT)/scm/log.xml:
	@$(ABS_PRINT_info) "Generating log index for $(APPNAME) from $(VPARENT) to-$(VERSION)"
	@mkdir -p $(@D)
	@svn $(SVNFLAGS) log --xml $(SVNURLTO) -v -r $(SVNFROMLREV):HEAD > $@

$(BUILDROOT)/scm/checksum.txt:
	@$(ABS_PRINT_info) "Generating checksum index for $(APPNAME)-$(VERSION)"
	@rm -rf __tmp_$(APPNAME)
	@svn $(SVNFLAGS) checkout $(SVNURLTO) __tmp_$(APPNAME)
	@find __tmp_$(APPNAME) -type f | xargs sha256sum | sed -e 's!__tmp_$(APPNAME)/!!g' > $@
	@rm -rf __tmp_$(APPNAME)

scm-release:: $(patsubst %,$(BUILDROOT)/scm/%, file-list.xml diff.xml log.xml checksum.txt)
