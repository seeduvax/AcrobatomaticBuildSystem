## ABS: Automated build system
## See ABS documentation for more details:
## - http://www.eduvax.net/gitweb
## - reference documentation: ref #e3782807
## --------------------------------------------------------------------
## Application level build services
## --------------------------------------------------------------------
## 
ABS_FROMAPP:=true
export ABS_FROMAPP

include $(ABSROOT)/core/common.mk

# re-include in case that common variables are used in this cfg.
include $(PRJROOT)/app.cfg
-include local.cfg

JENKINS_USER?=jenkins
DISTUSER?=$(USER)
DISTHOST?=$(DISTUSER)@moneta.eduvax.net
DISTREPO?=$(DISTHOST):/home/httpd/www.eduvax.net/www/dist
## - MAXJOBS: max allowed parallel tasks.
MAXJOBS:=$(shell getconf _NPROCESSORS_ONLN)
## - MMARGS: extra make arguments to forward to modules sub-make.
MMARGS?=-j$(MAXJOBS)


VERSION_FIELDS:=$(subst ., ,$(VERSION))
VMAJOR:=$(word 1,$(VERSION_FIELDS))
VMEDIUM:=$(word 2,$(VERSION_FIELDS))
VMINOR:=$(word 3,$(VERSION_FIELDS))
VSUFFIX:=$(patsubst %,.%,$(word 4,$(VERSION_FIELDS)))

ifeq ($(ABS_SCM_TYPE),null)
VERSION:=$(VERSION)e
endif
ifeq ($(WORKSPACE_IS_TAG),0)
VERSION:=$(VERSION)d
RELEASE_IDENTIFIER:=
else
MODE=release
RELEASE_IDENTIFIER:=$(VMAJOR).$(VMEDIUM)$(RELEASE)$(VSUFFIX)
endif
##  - PREFIX: installation prefix (default is /opt/<appname>-<version>)
PREFIX=/opt/$(APPNAME)-$(VERSION)

ifeq ($(MODULES),)
# search for module only if not explicitely defined from app.cfg.
MODULES_DEPS:=$(filter-out $(patsubst %,mod.%,$(NOBUILD)),$(patsubst %/Makefile,mod.%,$(shell ls */Makefile)))
MODULES:=$(MODULES_DEPS) $(patsubst %,warnnobuild.%,$(NOBUILD))
MODULES_TEST:=$(filter-out $(patsubst %,testmod.%,$(NOBUILD) $(NOTEST)),$(patsubst %/Makefile,testmod.%,$(shell ls */Makefile))) $(patsubst %,warnnotest.%,$(NOTEST) $(NOBUILD))
MODULES_VALGRINDTEST:=$(filter-out $(patsubst %,valgrindtestmod.%,$(NOBUILD) $(NOTEST)),$(patsubst %/Makefile,valgrindtestmod.%,$(shell ls */Makefile))) $(patsubst %,warnnotest.%,$(NOTEST) $(NOBUILD))
MODULES_TESTBUILD:=$(filter-out $(patsubst %,testbuildmod.%,$(NOBUILD)),$(patsubst %/Makefile,testbuildmod.%,$(shell ls */Makefile))) $(patsubst %,warnnobuild.%,$(NOBUILD))
else
MODULES:=$(patsubst %,mod.%,$(MODULES))
endif
EXPMOD?=$(patsubst mod.%,%,$(MODULES))
DOLLAR=$$
##  - NOBUILD: list of modules to *not* build.

## 
## Make targets:
## 

##  - all (default): builds all modules. Useful variable: NOBUILD.
all: $(MODULES)

##  - test: builds modules, tests and launch tests.
test: $(MODULES_TEST)
	@rm -rf build/unit_test_results
	@mkdir -p build/unit_test_results
	@cp build/*/$(MODE)/test/*.xml build/unit_test_results

##  - valgrindtest: builds modules, tests and launch tests using valgind.
valgrindtest: $(MODULES_VALGRINDTEST)
	@rm -rf build/unit_test_results
	@mkdir -p build/unit_test_results
	cp $(TTARGETDIR)/*.xml build/unit_test_results

##  - test: builds modules and tests.
testbuild: $(MODULES_TESTBUILD)

##  - All: clean and build all
All:
	make clean
	make all

##  - clean: deletes all built files and build process outputs
# User can have not the right to modify permission, but have the right to remove elements. => not failed on chmod error.
clean:
	@$(ABS_PRINT_info) "Cleaning ..."
	@$(ABS_PRINT_info) "Changing permissions of build"
	@-if [ -d build ]; then chmod -R u+w build 2> /dev/null; fi
	@$(ABS_PRINT_info)  "Changing permissions of dist"
	@-if [ -d dist ]; then chmod -R u+w dist 2> /dev/null; fi
	@$(ABS_PRINT_info) "Removing build"
	@rm -rf build
	@$(ABS_PRINT_info) "Removing dist"
	@rm -rf dist
	@$(ABS_PRINT_info) "Removing tmp"
	@rm -rf tmp

build/.moddeps.mk:
	@mkdir -p build
	@for mod in $(patsubst mod.%,%,$(MODULES_DEPS)) ; do \
	for element in mod testmod testbuildmod valgrindtestmod; do \
	echo "$$element.$$mod:: "'$$(patsubst %,'`echo $$element`.%','`grep 'USE\(LK\)*MOD=' $$mod/module.cfg | cut -d '=' -f 2`")" >> $@ ; \
	echo >> $@ ; \
	done; \
	done

mod.%::
	make $(MMARGS) -C $*

-include build/.moddeps.mk

testmod.%:
	make $(MMARGS) -C $* test

valgrindtestmod.%:
	make $(MMARGS) -C $* valgrindtest

testbuildmod.%:
	make $(MMARGS) -C $* testbuild

warnnobuild.%:
	@$(ABS_PRINT_warning) "module $* build is disabled."

warnnotest.%:
	@$(ABS_PRINT_warning) "module $* test is disabled."

##  - newmod <module name>: creates file structure for a new module
ifeq ($(word 1,$(MAKECMDGOALS)),newmod)
NEWMODNAME=$(word 2,$(MAKECMDGOALS))$(M)
.PHONY: newmod
newmod:
	mkdir $(NEWMODNAME)
	mkdir $(NEWMODNAME)/include
	mkdir $(NEWMODNAME)/src
	cp $(ABSROOT)/core/bootstrap.mk $(NEWMODNAME)/Makefile
	printf "MODNAME=$(NEWMODNAME)\nMODTYPE=library\nUSEMOD=\nLINKLIB=\nCFLAGS+=\nLDFLAGS+=\n" > $(NEWMODNAME)/module.cfg

$(NEWMODNAME):

endif
##  - branch: create a new branch from the current one
branch:
	$(ABSROOT)/core/scmtools.sh branch

help:
	@grep "^## " $(MAKEFILE_LIST) | sed -e 's/^.*## //'

_extra_import_defs_=$(subst >,\n,$(shell echo '$(extra_import_defs)'))

dist/$(APPNAME)-$(VERSION)/import.mk:
	@rm -rf dist
	@$(ABS_PRINT_info) "Compilation of the project in mode: $(MODE)"
	@make TRDIR=$$PWD/dist/$(APPNAME)-$(VERSION) MODE=$(MODE) $(filter-out $(patsubst %,mod.%,$(NODISTMOD)),$(MODULES))
	@test -f export.mk && \
	m4 -D__app__=$(APPNAME) -D__version__=$(VERSION) export.mk -D__uselib__="$(USELIB)" > $$PWD/dist/$(APPNAME)-$(VERSION)/import.mk || \
	printf '\n-include $$(dir $$(lastword $$(MAKEFILE_LIST)))/.abs/index.mk\n$$(eval $$(call extlib_import_template,$(APPNAME),$(VERSION),$(USELIB)))\n$(_extra_import_defs_)\n\n' > $@
	@test -x extradist.sh && VERSION=$(VERSION) APPNAME=$(APPNAME) ./extradist.sh `dirname $@` || :
	@mkdir -p dist/$(APPNAME)-$(VERSION)/include/$(APPNAME)
	@for headerdir in $(patsubst %,%/include,$(filter-out $(NODISTMOD),$(EXPMOD))); \
	do cp -r $$headerdir dist/$(APPNAME)-$(VERSION) ; \
	test -d .svn && find dist -name ".svn" | xargs rm -rf ; \
	: ; \
	done 
	@rm -rf dist/$(APPNAME)-$(VERSION)/obj
	@rm -rf dist/$(APPNAME)-$(VERSION)/build.log
	@rm -rf dist/$(APPNAME)-$(VERSION)/.*.dep


DISTTAR:=tar cvzf dist/$(APPNAME)-$(VERSION).$(ARCH).tar.gz -C dist --exclude obj --exclude extlib --exclude extlib.nodist $(APPNAME)-$(VERSION)

dist/$(APPNAME)-$(VERSION).$(ARCH).tar.gz: dist/$(APPNAME)-$(VERSION)/import.mk
ifeq ($(RELEASE_IDENTIFIER),)
	@$(DISTTAR)
else
	@ln -sf $(APPNAME)-$(VERSION) dist/$(APPNAME)-$(RELEASE_IDENTIFIER)
	@$(DISTTAR) $(APPNAME)-$(RELEASE_IDENTIFIER)
endif

##  - dist: creates binary package
dist: dist/$(APPNAME)-$(VERSION).$(ARCH).tar.gz

##  - echoDID: displays package identifier
echoDID:
	@echo $(APPNAME)-$(VERSION).$(ARCH)

pubfile: $(FILE)
	scp $(FILE) $(DISTREPO)/$(ARCH)/`basename $(FILE)`

##  - install [PREFIX=<install path>]: installs the application
install: dist/$(APPNAME)-$(VERSION)/import.mk
	@mkdir -p $(PREFIX)
	@$(ABS_PRINT_info) "Copying binaries..."
	@test -d dist/$(APPNAME)-$(VERSION)/bin && cp -r dist/$(APPNAME)-$(VERSION)/bin $(PREFIX)/ || :
	@test -d dist/$(APPNAME)-$(VERSION)/sbin && cp -r dist/$(APPNAME)-$(VERSION)/sbin $(PREFIX)/ || :
	@$(ABS_PRINT_info)  "Copying header files..."
	@test -d dist/$(APPNAME)-$(VERSION)/include && cp -r dist/$(APPNAME)-$(VERSION)/include $(PREFIX)/ || :
	@$(ABS_PRINT_info)  "Copying configuration files..."
	@test -d dist/$(APPNAME)-$(VERSION)/etc && cp -r dist/$(APPNAME)-$(VERSION)/etc $(PREFIX)/ || : 
	@$(ABS_PRINT_info)  "Copying libraries..."
	@test -d dist/$(APPNAME)-$(VERSION)/lib && cp -r dist/$(APPNAME)-$(VERSION)/lib $(PREFIX)/ || :
	@$(ABS_PRINT_info)  "Copying shared files..."
	@test -d dist/$(APPNAME)-$(VERSION)/share && cp -r dist/$(APPNAME)-$(VERSION)/share $(PREFIX)/ || :
	@$(ABS_PRINT_info)  "Copying dependancies..."
	@for lib in `ls dist/$(APPNAME)-$(VERSION)/extlib/ | fgrep -v cppunit-` ; do \
	$(ABS_PRINT_info) "  Processing $$lib..." ; \
	test -d dist/$(APPNAME)-$(VERSION)/extlib/$$lib && chmod -R +rwX dist && ( tar -C dist/$(APPNAME)-$(VERSION)/extlib/$$lib -cf - include lib lib64 etc bin sbin share | tar -C $(PREFIX) -xf - ) || cp dist/$(APPNAME)-$(VERSION)/extlib/$$lib $(PREFIX)/lib ; \
	done
	@if [ ! -z "$(INSTALL_EXCLUDE_PATTERNS)" ]; then pwd=$$PWD; for p in $(INSTALL_EXCLUDE_PATTERNS); do $(ABS_PRINT_info) "Removing pattern $$p from installation ..."; cmd="cd $(PREFIX) ; find . -path '$$p' | xargs rm -rf 2> /dev/null ; cd $$pwd"; eval $$cmd; done; fi

dist/$(APPNAME)-$(VERSION).$(ARCH)-install.bin:
	@make PREFIX=tmp/$(APPNAME)-$(VERSION) INSTALL_EXCLUDE_PATTERNS=$(INSTALL_EXCLUDE_PATTERNS) install
	@tar -C tmp -cvzf tmp/arch.tar.gz $(APPNAME)-$(VERSION)/
	@sed -e 's/__appname__/$(APPNAME)/g' $(ABSROOT)/core/install-template.sh | sed -e 's/__version__/$(VERSION)/g' > "$@"
	cat tmp/arch.tar.gz >> "$@"
	chmod +x "$@"

##  - distinstall: builds installation package.
distinstall: dist/$(APPNAME)-$(VERSION).$(ARCH)-install.bin

KVERSION:=$(shell uname -r)
##  - kdistinstall: builds linux kernel modules installation package
kdistinstall: dist/$(APPNAME)_lkm-$(VERSION)-$(KVERSION)-install.bin

KMODULES:=$(filter-out $(patsubst %,mod.%,$(NOBUILD)),$(patsubst %,mod.%,$(shell ls | grep _lkm)))
dist/$(APPNAME)_lkm-$(VERSION)-$(KVERSION)-install.bin:
	@make TRDIR=$$PWD/dist/$(APPNAME)-$(VERSION) MODE=release $(KMODULES)
	tar -C dist/$(APPNAME)-$(VERSION) -cvzf dist/arch.tar.gz etc/ lib/
	sed -e 's/__app__/$(APPNAME)/g' $(ABSROOT)/core/kinstall-template.sh | sed -e 's/__version__/$(VERSION)/g' | sed -e 's/__kversion__/$(KVERSION)/g' > "$@"
	cat dist/arch.tar.gz >> "$@"
	chmod +x "$@"
	rm dist/arch.tar.gz

pubdist: dist/$(APPNAME)-$(VERSION).$(ARCH).tar.gz
	@$(ABS_PRINT_info)  "Publishing dist archive $^ $(USER) on $(DISTREPO)"
	@-test $(USER) = $(JENKINS_USER) && \
	scp $^ $(DISTREPO)/$(ARCH)/$(APPNAME)-$(VERSION).$(ARCH).tar.gz
ifneq ($(RELEASE_IDENTIFIER),)
	@ssh $(DISTHOST) rm -rf $(patsubst $(DISTHOST):%,%,$(DISTREPO))/$(ARCH)/$(APPNAME)-$(RELEASE_IDENTIFIER).$(ARCH).tar.gz
	@ssh $(DISTHOST) ln -sf $(APPNAME)-$(VERSION).$(ARCH).tar.gz $(patsubst $(DISTHOST):%,%,$(DISTREPO))/$(ARCH)/$(APPNAME)-$(RELEASE_IDENTIFIER).$(ARCH).tar.gz
endif

pubinstall: dist/$(APPNAME)-$(VERSION).$(ARCH)-install.bin
	@$(ABS_PRINT_info)  "Publishing dist archive $^ $(USER) on $(DISTREPO)"
	@-test $(USER) = $(JENKINS_USER) && \
	scp $^ $(DISTREPO)/$(ARCH)/$(APPNAME)-$(VERSION).$(ARCH)-install.bin

##  - cint: full package build, to be used for the continuous integration
##    process (for builds from jenkins or any similar tool).
##	  Overload CINT_TEST_TARGET and/or CINT_PUB_TARGET to use alternate
##    custom test and/or built archive publish target.
ifeq (cint,$(filter cint,$(MAKECMDGOALS)))
CINT_TEST_TARGET:=test
CINT_PUB_TARGET:=$(shell grep -q exe */module.cfg && echo pubinstall || echo pubdist)
CINTMAKECMD=MODE=release nice -n20 make
endif
cint:
	@$(ABS_PRINT_info) "Starting full build..."
	@$(ABS_PRINT_info) "Test Target: $(CINT_TEST_TARGET)"
	@$(ABS_PRINT_info) "Pub Target: $(CINT_PUB_TARGET)"
	@$(CINTMAKECMD) clean && $(CINTMAKECMD) $(CINT_TEST_TARGET) && $(CINTMAKECMD) $(CINT_PUB_TARGET)

ifneq ($(filter klocwork, $(MAKECMDGOALS)),)
include $(ABSROOT)/klocwork/main.mk
endif

ifneq ($(IMPORT_ABSMOD),)
include $(patsubst %,$(ABSROOT)/%/main.mk,$(IMPORT_ABSMOD))
endif
