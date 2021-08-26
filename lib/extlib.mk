VABS:=99.99.99
PRJDIR=$(shell pwd)
ABSWS:=$(PRJDIR)/../.absws
PRJROOT:=$(PRJDIR)/../..
_FAKE_ABS_DOWNLOAD:=$(shell mkdir -p $(ABSWS); test -d $(ABSWS)/abs-$(VABS) || ln -sf ../../ $(ABSWS)/abs-$(VABS))

all:

include ../../core/common.mk
include extlib.cfg

LICENSEFILE?=none

BUILDDIR=$(PRJDIR)/../../build
SRCDIR=$(BUILDDIR)/$(PRODUCT)-$(VERSION)
INSTDIR=$(SRCDIR)/b/$(PRODUCT)-$(VERSION)$(VPATCH)
DISTARCH=$(BUILDDIR)/$(PRODUCT)-$(VERSION)$(VPATCH).$(ARCH).tar.gz
PATCHES=$(patsubst %,.apply.%,$(wildcard *.patch))
SRCARCH=$(BUILDDIR)/$(PRODUCT)-$(VERSION)-src.tar.gz
HASPRODUCTMK=$(shell test -r product.mk && echo 1 || echo 0)
DEPS=$(patsubst %,$(BUILDDIR)/%.$(ARCH).tar.gz,$(USELIB))

all: $(DISTARCH)

clean:
	rm -rf $(DISTARCH) $(SRCDIR)

$(BUILDDIR)/%.$(ARCH).tar.gz:
	make -C $(patsubst $(BUILDDIR)/%.$(ARCH).tar.gz,../%,$@)

$(SRCARCH):
	mkdir -p $(@D)
	wget $(SRCURL) -O $(SRCARCH)

$(SRCDIR): $(SRCARCH) $(DEPS)
	@mkdir -p $@
	@echo "Decompressing source archive..."
	@tar -xzf $(SRCARCH) -C $(BUILDDIR)
	$(POSTEXTRACT)

.apply.%.patch: %.patch
	@echo "Applying patch $<"
	@cd $(SRCDIR) ; patch -p 1 < $(PRJDIR)/$< | tee $@

ifeq ($(HASPRODUCTMK),1)
$(SRCDIR)/Makefile: $(SRCDIR) product.mk
	cp product.mk $@
	@cd ${@D} ;\
	$(POSTCONFIGURE)
else
ifneq ($(HASCONFIGURE),0)
$(SRCDIR)/configure: $(SRCDIR)

$(SRCDIR)/Makefile: $(SRCDIR)/configure
	@cd ${@D} ;\
	./configure --prefix $(SRCDIR)/b/$(PRODUCT)-$(VERSION) $(ACFLAGS)
	$(POSTCONFIGURE)
endif

ifeq ($(HASNATIVEMAKE),1)
$(SRCDIR)/Makefile: $(SRCDIR)
endif
endif

$(INSTDIR)/import.mk: $(SRCDIR)/Makefile $(PATCHES)
	mkdir -p ${@D}
	@make -C $(SRCDIR) $(MARGS)
	$(POSTMAKE)	
	@grep -q "^install:" $(SRCDIR)/Makefile && make -C $(SRCDIR) $(MIARGS) install || :
	@printf '# buildscripts generated dependency file\n$$(eval $$(call extlib_import_template,$(PRODUCT),$(VERSION)$(VPATCH),$(USELIB)))\n$(IMPORTEXTRA)\n' > $@
	@test -r $(LICENSEFILE) && { mkdir -p ${@D}/share ; cp $(LICENSEFILE) ${@D}/share/$(PRODUCT)-$(VERSION).license; } || :
	@echo Done
	$(POSTINSTALL)

$(DISTARCH): $(EXTRATARGETS) $(INSTDIR)/import.mk
	@echo "Compressing archive..."
	@tar -czf $(DISTARCH) -C $(SRCDIR)/b $(PRODUCT)-$(VERSION)$(VPATCH)

