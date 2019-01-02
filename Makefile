include app.cfg
PREFIX=/home/httpd/www/dist/

WORKSPACE_IS_TAG:=$(shell LANG=C svn info | grep "^URL:" | grep -c "/tags/")
ifeq ($(WORKSPACE_IS_TAG),0)
VERSION:=$(VERSION)d
define link_command
endef
else
BRANCH:=$(basename $(VERSION))
define link_command
ln -sf $(patsubst $(PREFIX)/noarch/%,%,$@) $(patsubst %-$(VERSION).tar.gz,%-$(BRANCH).tar.gz,$@)
endef
endif

DISTPACKAGES:=$(patsubst %,dist/abs.%-$(VERSION).tar.gz,$(ABS_PACKAGES))

dist/abs.%-$(VERSION).tar.gz:
	@mkdir -p $(@D)/abs-$(VERSION)
	@tar cf - $(patsubst dist/abs.%-$(VERSION).tar.gz,%,$@) --exclude .svn | tar xf - -C $(@D)/abs-$(VERSION)
	@tar cvzf $@ -C $(@D) abs-$(VERSION)/$(patsubst dist/abs.%-$(VERSION).tar.gz,%,$@)

dist: $(DISTPACKAGES)
	test -d dist/noarch || ln -sf $$PWD/dist dist/noarch

clean:
	rm -rf dist
	-rm -rf .abs
	
install: $(patsubst dist/%,$(PREFIX)/noarch/%,$(DISTPACKAGES))

$(PREFIX)/noarch/abs.%: dist/abs.%
	cp $^ $@
	$(link_command)
