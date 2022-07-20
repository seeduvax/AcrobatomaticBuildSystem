ifeq ($(MAKECMDGOALS),dist)
include app.cfg
# overloading dist
PRJROOT:=$(CURDIR)
ABSROOT=$(CURDIR)

# dummy rule to disable attempt to download local.cfg. I (S.Devaux) don't 
# really understand why this workaround is needed. Something strange with
# incuding common.mk directly.
%/local.cfg:
	@:

include core/common.mk
ifeq ($(WORKSPACE_IS_TAG),0)
VERSION:=$(VERSION)d
endif

DISTPACKAGES:=$(patsubst %,dist/abs.%-$(VERSION).tar.gz,$(ABS_PACKAGES))

dist/abs.%-$(VERSION).tar.gz:
	@mkdir -p $(@D)/abs-$(VERSION)
	@tar --exclude=.svn -cf - $* | tar xf - -C $(@D)/abs-$(VERSION)
	@sed -i 's/__ABS_MODULE_VERSION_MARKER__/$(VERSION)/g' $(@D)/abs-$(VERSION)/$*/main.mk
	@cp LICENSE  $(@D)/abs-$(VERSION)/$*/
	@tar cvzf $@ -C $(@D) abs-$(VERSION)/$*

dist: $(DISTPACKAGES)

$(PREFIX)/noarch/abs.%: dist/abs.%
	cp $^ $@
else
include core/bootstrap.mk
endif
