
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
@git tag -a $(APPNAME)-$(TAG_VERSION) $(TAG_REVISION) -m "$(VISSUE) $(COMMENT)" && \
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
