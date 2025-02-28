# This library permit to test an archive with a different name than the .so generated (case of eigen, jsoncpp, ...)

ARCHNAME=testlib2
VERSION=1.0.1
DIRVERSION=$(ARCHNAME)-$(VERSION)
BUILDROOT=build
BUILDDIR=$(BUILDROOT)/$(DIRVERSION)

BINARY_FILE=$(BUILDDIR)/lib/lib$(ARCHNAME).so
ARCHIVE_FILE=$(BUILDROOT)/$(DIRVERSION).NotALinux.tar.gz
IMPORT_MK=$(BUILDDIR)/import.mk

all: $(ARCHIVE_FILE)

$(BINARY_FILE): source.cpp
	@mkdir -p $(@D)
	@gcc -shared $< -o $@

$(ARCHIVE_FILE): $(BINARY_FILE) $(IMPORT_MK)
	@tar -czf $@ -C $(BUILDROOT) $(DIRVERSION)

$(IMPORT_MK):
	@mkdir -p $(@D)
	@echo '_app_'$(ARCHNAME)'_dir:=$$(dir $$(lastword $$(MAKEFILE_LIST)))' > $@.tmp
	@echo '$$(eval $$(call extlib_import_template,'$(ARCHNAME)','$(VERSION)',))' >> $@.tmp
	@mv $@.tmp $@