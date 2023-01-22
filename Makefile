ifeq ($(MAKECMDGOALS),dist)
include app.cfg
# overloading dist
PRJROOT:=$(CURDIR)
ABSROOT=$(CURDIR)

# dummy rules to disable attempt to download local.cfg, app.cfg. I (S.Devaux) 
# don't # really understand why this workaround is needed. Something strange
#  with incuding common.mk directly.
%/local.cfg:
	@:

%/app.cfg:
	@:

include core/common.mk
ifeq ($(WORKSPACE_IS_TAG),0)
VERSION:=$(VERSION)d
endif

dist/abs.core-$(VERSION).tar.gz:
	@mkdir -p $(@D)/abs-$(VERSION)
	@tar --exclude=.svn -cf - $(ABS_PACKAGES) | tar xf - -C $(@D)/abs-$(VERSION)
	@sed -i 's/__ABS_MODULE_VERSION_MARKER__/$(VERSION)/g' $(@D)/abs-$(VERSION)/core/main.mk
	@cp LICENSE  $(@D)/abs-$(VERSION)/core/
	@tar cvzf $@ -C $(@D) $(patsubst %,abs-$(VERSION)/%,$(ABS_PACKAGES))

dist: dist/abs.core-$(VERSION).tar.gz

$(PREFIX)/noarch/abs.%: dist/abs.%
	cp $^ $@
else
include core/bootstrap.mk
endif
