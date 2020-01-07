ABS_SCM_TYPE:=svn
WORKSPACE_IS_TAG:=$(shell LANG=C svn info | grep "^URL:" | grep -c "/tags/")
REVISION:=$(shell svnversion)
SVNROOT:=$(shell LANG=C svn info | grep "^Repository Root:" | sed -e 's/^Repository Root: //g')
# SVNPRJROOT is the directory where are the tags, branches and trunk directories
SVNPRJROOT?=$(SVNROOT)
SVNURL:=$(shell LANG=C svn info | grep "^URL:" | sed -e 's/^URL: //g')

# backward compability.
TAG_REVISION?=$(SVN_REVISION)
TAG_REVISION?=HEAD

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
