
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
