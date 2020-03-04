PRJROOT:=$(CURDIR)
ABSROOT=$(CURDIR)
include app.cfg
ifeq ($(MAKECMDGOALS),dist)
# overloading dist
include core/common.mk
ifeq ($(WORKSPACE_IS_TAG),0)
VERSION:=$(VERSION)d
endif

DISTPACKAGES:=$(patsubst %,dist/abs.%-$(VERSION).tar.gz,$(ABS_PACKAGES))

dist/abs.%-$(VERSION).tar.gz:
	@mkdir -p $(@D)/abs-$(VERSION)
	@tar cf - $(patsubst dist/abs.%-$(VERSION).tar.gz,%,$@) --exclude .svn | tar xf - -C $(@D)/abs-$(VERSION)
	@sed -i 's/__ABS_MODULE_VERSION_MARKER__/$(VERSION)/g' $(@D)/abs-$(VERSION)/$(patsubst dist/abs.%-$(VERSION).tar.gz,%,$@)/main.mk
	@cp LICENSE  $(@D)/abs-$(VERSION)/$(patsubst dist/abs.%-$(VERSION).tar.gz,%,$@)/
	@tar cvzf $@ -C $(@D) abs-$(VERSION)/$(patsubst dist/abs.%-$(VERSION).tar.gz,%,$@)

dist: $(DISTPACKAGES)

$(PREFIX)/noarch/abs.%: dist/abs.%
	cp $^ $@
else
include core/main.mk
endif
