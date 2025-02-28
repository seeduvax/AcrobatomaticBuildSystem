## ABS: Automated build system
## See ABS documentation for more details:
## - http://www.eduvax.net/gitweb
## - reference documentation: ref #e3782807
## --------------------------------------------------------------------
## Application level build services
## --------------------------------------------------------------------

ABS_FROMAPP:=true
export ABS_FROMAPP

## 
## Make variables:
## 

include $(ABSROOT)/core/common.mk

MODULES_TARGET:=$(patsubst %,$(PRJOBJDIR)/%/.done,$(MODULES_DEPS)) $(patsubst %,warnnobuild.%,$(NOBUILD))
MODULES_TEST:=$(filter-out $(patsubst %,testmod.%,$(NOBUILD) $(NOTEST)),$(patsubst %,testmod.%,$(MODULES))) $(patsubst %,warnnotest.%,$(NOTEST) $(NOBUILD))
MODULES_VALGRINDTEST:=$(filter-out $(patsubst %,valgrindtestmod.%,$(NOBUILD) $(NOTEST)),$(patsubst %,valgrindtestmod.%,$(MODULES))) $(patsubst %,warnnotest.%,$(NOTEST) $(NOBUILD))
MODULES_TESTBUILD:=$(filter-out $(patsubst %,testbuildmod.%,$(NOBUILD)),$(patsubst %,testbuildmod.%,$(MODULES))) $(patsubst %,warnnobuild.%,$(NOBUILD))
JENKINS_USER?=jenkins
DISTUSER?=$(USER)
DISTHOST?=$(DISTUSER)@moneta.eduvax.net
DISTREPO?=$(DISTHOST):/home/httpd/www.eduvax.net/www/dist
##  - MAXJOBS: max allowed parallel tasks.
MAXJOBS:=$(shell getconf _NPROCESSORS_ONLN)
##  - MMARGS: extra make arguments to forward to modules sub-make.
MMARGS?=-j$(MAXJOBS)

##  - PREFIX: installation prefix (default is /opt/<appname>-<version>)
PREFIX=/opt/$(APPNAME)-$(VERSION)

##  - DIST_EXCLUDE: pattern for files to be excluded on packaging.
##      (default: share/*/tex)
DIST_EXCLUDE+=share/doc/$(APPNAME)/tex obj extlib extlib.nodist
##  - INSTALLTAR_EXCLUDE: pattern for files to be excluded on install binary.
##      (default: share/doc/*)
INSTALLTAR_EXCLUDE+=.abs import.mk
##  - LIGHT_INSTALLER: when set to 1, add share/*/doxygen and include to the 
##      list of file to exclude on packaging.
ifeq ($(LIGHT_INSTALLER),1)
INSTALLTAR_EXCLUDE+=share/doc/*/doxygen include src
endif
##  - DISTTARFLAGS: arguments to add to tar command when packing files on dist
##      and distinstall target.
DISTTARFLAGS+=$(patsubst %,--exclude=%,$(DIST_EXCLUDE))

##  - INSTALLTARFLAGS: arguments to add to tar command when packing files on distinstall target.
INSTALLTARFLAGS+=$(patsubst %,--exclude=%,$(INSTALLTAR_EXCLUDE))

# EXPMOD: list of public modules for which includes are inserted into the distribuable archive.
EXPMOD?=$(MODULES_DEPS)
EXPMOD:=$(filter-out $(NODISTMOD),$(sort $(EXPMOD)))
DOLLAR=$$
##  - NOBUILD: list of modules to *not* build.

# for clangd server used for modern editors (VSCode...) completion/introspection engine
CLANGD_DB=compile_commands.json

define gen-clangd-db
@echo "[" > $(CLANGD_DB)
@find $(BUILDROOT) -name '*.o.json' | xargs cat >> $(CLANGD_DB)
@sed -i "$$(wc -l < $(CLANGD_DB))s/,$$//" $(CLANGD_DB)
@echo "]" >> $(CLANGD_DB)
endef

## 
## Make targets:
## 

##  - all (default): builds all modules. Useful variable: NOBUILD.
all: $(MODULES_TARGET)
	$(gen-clangd-db)

##  - test: builds modules, tests and launch tests.
ifneq ($(shell ls $(PRJROOT)/*/test 2>/dev/null),)
define test-synthesis
	@rm -rf build/unit_test_results
	@mkdir -p build/unit_test_results
	@$(if $(wildcard $(TRDIR)/test/$(APPNAME)_*.xml),cp $(TRDIR)/test/$(APPNAME)_*.xml build/unit_test_results)
endef
define test-summary
	@$(ABS_PRINT_info) "#### #### Tests summary #### ####"
	@for report in `ls build/unit_test_results/*.xml`; do $(ABS_PRINT_info) "Test result: "`basename $$report` ; xsltproc --stringparam mode short $(ABSROOT)/core/xunit2txt.xsl $$report;  done
endef

testsummary:
	$(test-summary)

test: $(MODULES_TEST)
	$(test-synthesis)
ifeq ($(MAKECMDGOALS),test)
	$(test-summary)
endif

##  - valgrindtest: builds modules, tests and launch tests using valgind.
valgrindtest: $(MODULES_VALGRINDTEST)
	$(test-synthesis)
else
test: $(MODULES_TEST)
	@$(ABS_PRINT_error) "No test found in this project."
	@$(ABS_PRINT_error) "To create a test in your project. Go to the module directory of "
	@$(ABS_PRINT_error) "the class to be tested and invoke:"
	@$(ABS_PRINT_error) "	make newtest <NameOfClassToTest>"
	@$(ABS_PRINT_error) "and edit edit the file created in the test directory."

valgrindtest: test

endif

##  - testbuild: builds modules and tests.
testbuild: $(MODULES_TESTBUILD)
	$(gen-clangd-db)

##  - All: clean and build all
All:
	make clean
	make all

##  - clean: deletes all built files and build process outputs
# User can have not the right to modify permission, but have the right to remove elements. => not failed on chmod error.
clean: cleandist cleanbuild

##  - loadDependencies: load all the dependencies of the project.
loadDependencies: app.cfg
	@$(ABS_PRINT_info) "Dependencies loaded"

#   - cleanbuild: remove the build directory
cleanbuild:
	@$(ABS_PRINT_info) "Cleaning build ..."
	@$(ABS_PRINT_info) "Changing permissions of build"
	@-test ! -d build || chmod -R u+w build 2> /dev/null
	@$(ABS_PRINT_info) "Removing build"
	@rm -rf build
	@! test -f $(CLANGD_DB) || rm $(CLANGD_DB)

$(PRJOBJDIR)/%/.depready::
	@MODNAME=`cat $*/module.cfg | grep -E "^MODNAME" | sed -E 's/.*=(.*)/\1/g'` && test "$$MODNAME" = "$*" || $(ABS_PRINT_warning) "The name of the module $$MODNAME doesn't match the name of the module directory $*. This can have side effects."
	@mkdir -p $(@D)
	@mkdir -p $(TRDIR)/.abs/content
	@echo "# "`date` > $@

$(PRJOBJDIR)/%/.done: $(PRJOBJDIR)/%/.depready $(PRJOBJDIR)/%/moddeps.mk
	@$(ABS_PRINT_info) "Building module $(patsubst $(PRJOBJDIR)/%/.done,%,$@)..."
	@MODNAME=`cat $*/module.cfg | grep -E "^MODNAME" | sed -E 's/.*=(.*)/\1/g'` && test "$$MODNAME" = "$*" || $(ABS_PRINT_warning) "The name of the module $$MODNAME doesn't match the name of the module directory $*. This can have side effects."
	@mkdir -p $(@D)
	@mkdir -p $(TRDIR)/.abs/content
	@touch $(TRDIR)/obj/$*/files.ts
	@+make $(MMARGS) MODE=$(MODE) -C $* && date > $@
	@find $(TRDIR) -type f -cnewer $(TRDIR)/obj/$*/files.ts | grep -v $(TRDIR)/obj | sed 's~$(TRDIR)/~~g' | grep -E -v "^$(subst *,.*,$(subst $(_space_),|,$(DIST_EXCLUDE)))" > $(TRDIR)/.abs/content/$(APPNAME)_$*.filelist || true
	@$(if $(filter $*,$(EXPMOD)),test ! -d $*/include || find $*/include -type f | sed 's~^$*/~~g' >> $(TRDIR)/.abs/content/$(APPNAME)_$*.filelist)
	@rm -f $(TRDIR)/obj/$*/files.ts
	@$(ABS_PRINT_info) "Module $(patsubst $(PRJOBJDIR)/%/.done,%,$@) built."

# depends on mod.% to compile dependencies of module.
testmod.%: $(PRJOBJDIR)/%/.done
	make $(MMARGS) MODE=$(MODE) -C $* test

valgrindtestmod.%: $(PRJOBJDIR)/%/.done
	make $(MMARGS) MODE=$(MODE) -C $* valgrindtest

testbuildmod.%: $(PRJOBJDIR)/%/.done
	make $(MMARGS) MODE=$(MODE) -C $* testbuild

warnnobuild.%:
	@$(ABS_PRINT_warning) "module $* build is disabled."

warnnotest.%:
	@$(ABS_PRINT_warning) "module $* test is disabled."

##  - newmod <module name>: creates file structure for a new module
ifeq ($(word 1,$(MAKECMDGOALS)),newmod)
NEWMODNAME=$(word 2,$(MAKECMDGOALS))$(M)
.PHONY: newmod
newmod:
	@$(ABS_PRINT_info) "Creating new module $(NEWMODNAME)"
	@mkdir $(NEWMODNAME)
	@mkdir $(NEWMODNAME)/include
	@mkdir $(NEWMODNAME)/src
	@echo "# Generated make bootstrap, do not edit. Edit module.cfg to configure module build." > $(NEWMODNAME)/Makefile
	@echo "include ../Makefile" >> $(NEWMODNAME)/Makefile
	@printf "MODNAME=$(NEWMODNAME)\nMODTYPE=library\nUSEMOD=\nLINKLIB=\nCFLAGS+=\nLDFLAGS+=\n" > $(NEWMODNAME)/module.cfg

$(NEWMODNAME):
	@:

endif

##  - echoDID: displays package identifier
echoDID:
	@echo $(APPNAME)-$(VERSION).$(ARCH)

pubfile: $(FILE)
	scp $(FILE) $(DISTREPO)/$(ARCH)/$(<F)

include $(ABSROOT)/core/app-dist.mk

##  - cint: full package build, to be used for the continuous integration
##    process (for builds from jenkins or any similar tool).
##	  Overload CINT_TEST_TARGET and/or CINT_PUB_TARGET to use alternate
##    custom test and/or built archive publish target.
ifeq (cint,$(filter cint,$(MAKECMDGOALS)))
CINT_TEST_TARGET:=test
ifeq ($(WORKSPACE_IS_TAG),0)
CINT_PUB_TARGET:=null
else
CINT_PUB_TARGET:=$(shell grep -q exe */module.cfg && echo pubinstall || echo pubdist)
endif
CINTMAKECMD=MODE=release nice -n20 make
endif
cint:
	@$(ABS_PRINT_info) "Starting full build..."
	@$(ABS_PRINT_info) "Test Target: $(CINT_TEST_TARGET)"
	@$(ABS_PRINT_info) "Pub Target: $(CINT_PUB_TARGET)"
	@$(CINTMAKECMD) clean && $(CINTMAKECMD) $(CINT_TEST_TARGET) && $(CINTMAKECMD) $(CINT_PUB_TARGET) && $(CINTMAKECMD) testsummary

# empty dummy target just to be able to skip one step in the cint rule just above.
null:
	:


# update bootstrap makefile if needed.
ifneq ($(PRESERVEMAKEFILE),true)
Makefile: $(ABSROOT)/core/bootstrap.mk
	@$(ABS_PRINT_info) "Updating bootstrap makefile."
	@cp $< $@
endif


## 
## --------------------------------------------------------------------
## ABS management utilities.
## --------------------------------------------------------------------
##  - cleanabs: clean abs workdir (will remove all files cached by abs and abs
##    itself). Does not make any change inside your project tree.
cleanabs:
	@$(ABS_PRINT_info) "Setting write permissions to $(ABSWS)..."
	@chmod -R u+w $(ABSWS)/extlib $(ABSWS)/cache $(ABSROOT) 2> /dev/null
	@$(ABS_PRINT_info) "Cleaning ABS cache $(ABSWS)..."
	@rm -rf $(ABSWS)/extlib $(ABSWS)/cache 
	@$(ABS_PRINT_info) "Removing ABS files $(ABSROOT)..."
	@rm -rf $(ABSROOT)
	@$(ABS_PRINT_info) "ABS cleaning completed."

##  - purgeabs: purge (remove all) abs directory (will remove all files cached by abs and
##    all version of abs). Does not make any change inside your project tree.
purgeabs:
	@$(ABS_PRINT_info) "Setting write permissions to $(ABSWS)..."
	@chmod -R u+w $(ABSWS) 2> /dev/null
	@$(ABS_PRINT_info) "Removing ABS files and cache $(ABSWS)..."
	@rm -rf $(ABSWS)
	@$(ABS_PRINT_info) "ABS purge completed."

absclean: cleanabs

include $(ABSROOT)/core/app-scm.mk
include $(ABSROOT)/core/app-docker.mk
include $(ABSROOT)/core/app-vscode.mk


ifneq ($(IMPORT_ABSMOD),)
include $(patsubst %,$(ABSROOT)/%/main.mk,$(IMPORT_ABSMOD))
endif
