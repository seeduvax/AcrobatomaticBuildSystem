ABS_SCM_TYPE:=svn
WORKSPACE_IS_TAG:=$(shell LANG=C svn info | grep "^URL:" | grep -c "/tags/")
REVISION:=$(shell svnversion)
SVNROOT:=$(shell LANG=C svn info | grep "^Repository Root:" | sed -e 's/^Repository Root: //g')
SVNURL:=$(shell LANG=C svn info | grep "^URL:" | sed -e 's/^URL: //g')

# backward compability.
TAG_REVISION?=$(SVN_REVISION)
TAG_REVISION?=HEAD

define abs_scm_tag
@svn copy $(SVNFLAGS) $(SVNURL)@$(TAG_REVISION) $(SVNROOT)/tags/$(APPNAME)/$(APPNAME)-$(TAG_VERSION) -m "$(VISSUE) $(COMMENT)"
endef

define abs_scm_commit
@svn commit $(SVNFLAGS) -m "$1"
endef
