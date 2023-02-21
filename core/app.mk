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

JENKINS_USER?=jenkins
DISTUSER?=$(USER)
DISTHOST?=$(DISTUSER)@moneta.eduvax.net
DISTREPO?=$(DISTHOST):/home/httpd/www.eduvax.net/www/dist
## - MAXJOBS: max allowed parallel tasks.
MAXJOBS:=$(shell getconf _NPROCESSORS_ONLN)
## - MMARGS: extra make arguments to forward to modules sub-make.
MMARGS?=-j$(MAXJOBS)

ifeq ($(ABS_SCM_TYPE),null)
VERSION:=$(VERSION)e
endif
ifeq ($(WORKSPACE_IS_TAG),0)
VERSION:=$(VERSION)d
else
MODE=release
endif
ifneq ($(VFLAVOR),)
VERSION:=$(VERSION)_$(subst $(_space_),_,$(sort $(VFLAVOR)))
endif
##  - PREFIX: installation prefix (default is /opt/<appname>-<version>)
PREFIX=/opt/$(APPNAME)-$(VERSION)

##  - DIST_EXCLUDE: pattern for files to be excluded on packaging.
##      (default: share/*/tex)
DIST_EXCLUDE:=share/doc/$(APPNAME)/tex obj extlib extlib.nodist
INSTALLTAR_EXCLUDE:=.abs import.mk
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

ifeq ($(MODULES),)
# search for module only if not explicitely defined from app.cfg.
MODULES:=$(patsubst %/module.cfg,%,$(wildcard */module.cfg))
MODULES_DEPS:=$(filter-out $(NOBUILD),$(MODULES))
MODULES_TARGET:=$(patsubst %,mod.%,$(MODULES_DEPS)) $(patsubst %,warnnobuild.%,$(NOBUILD))
MODULES_TEST:=$(filter-out $(patsubst %,testmod.%,$(NOBUILD) $(NOTEST)),$(patsubst %,testmod.%,$(MODULES))) $(patsubst %,warnnotest.%,$(NOTEST) $(NOBUILD))
MODULES_VALGRINDTEST:=$(filter-out $(patsubst %,valgrindtestmod.%,$(NOBUILD) $(NOTEST)),$(patsubst %,valgrindtestmod.%,$(MODULES))) $(patsubst %,warnnotest.%,$(NOTEST) $(NOBUILD))
MODULES_TESTBUILD:=$(filter-out $(patsubst %,testbuildmod.%,$(NOBUILD)),$(patsubst %,testbuildmod.%,$(MODULES))) $(patsubst %,warnnobuild.%,$(NOBUILD))
else
MODULES_DEPS:=$(MODULES)
MODULES_TARGET:=$(patsubst %,mod.%,$(MODULES))
endif

ifneq ($(filter kdistinstall,$(MAKECMDGOALS)),)
KMODULES:=$(filter %_lkm,$(MODULES_DEPS))
MODULES_DEPS:=$(KMODULES)
MODULES_TARGET:=$(patsubst %,mod.%,$(KMODULES))
MODE:=release
endif

# EXPMOD: list of public modules for which includes are inserted into the distribuable archive.
EXPMOD?=$(MODULES_DEPS)
EXPMOD:=$(filter-out $(NODISTMOD),$(sort $(EXPMOD)))
DOLLAR=$$
##  - NOBUILD: list of modules to *not* build.

## for clangd server used for modern editors (VSCode...) completion/introspection engine
CLANGD_DB=compile_commands.json

define gen-clangd-db
@echo "[" > $(CLANGD_DB)
@find $(BUILDROOT) -name '*.o.json' | xargs cat >> $(CLANGD_DB)
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

$(BUILDROOT)/.abs/moddeps.mk:
	@$(ABS_PRINT_info) "Generating module dependencies file."
	@mkdir -p $(@D)
	@for mod in $(patsubst mod.%,%,$(MODULES_DEPS)) ; do \
	make OBJDIR=$(PRJOBJDIR)/$$mod INCLUDE_EXTLIB=false PRJROOT=$(PRJROOT) MODROOT=$(PRJROOT)/$$mod ABSROOT=$(ABSROOT) -C $$mod generateAppModsNeeds --makefile $(ABSROOT)/core/module-depends_standalone.mk --no-print-directory && \
	printf "mod.$$mod:: " >> $@.tmp && \
	cat $(PRJOBJDIR)/$$mod/moddeps.needs >> $@.tmp && echo "" >> $@.tmp; \
	done
	@mv $@.tmp $@

mod.%::
	@MODNAME=`cat $*/module.cfg | grep MODNAME | sed -E 's/.*=(.*)/\1/g'` && test "$$MODNAME" = "$*" || $(ABS_PRINT_warning) "The name of the module $$MODNAME doesn't match the name of the module directory $*. This can have side effects."
	@mkdir -p $(TRDIR)/obj/$*
	@mkdir -p $(TRDIR)/.abs/content
	@touch $(TRDIR)/obj/$*/files.ts
	make $(MMARGS) MODE=$(MODE) -C $* DEPS_MNGMT_LEVEL=DISABLED
	@find $(TRDIR) -type f -cnewer $(TRDIR)/obj/$*/files.ts | grep -v $(TRDIR)/obj | sed 's~$(TRDIR)/~~g' | grep -E -v "$(subst *,.*,$(subst $(_space_),|,$(DIST_EXCLUDE)))" > $(TRDIR)/.abs/content/$(APPNAME)_$*.filelist || true
	@$(if $(filter $*,$(EXPMOD)),test ! -d $*/include || find $*/include -type f | sed 's~^$*/~~g' >> $(TRDIR)/.abs/content/$(APPNAME)_$*.filelist)
	@rm -f $(TRDIR)/obj/$*/files.ts

ifeq ($(filter clean%,$(MAKECMDGOALS)),)
include $(BUILDROOT)/.abs/moddeps.mk
endif

# depends on mod.% to compile dependencies of module.
testmod.%: mod.%
	make $(MMARGS) MODE=$(MODE) -C $* test DEPS_MNGMT_LEVEL=DISABLED

valgrindtestmod.%: mod.%
	make $(MMARGS) MODE=$(MODE) -C $* valgrindtest DEPS_MNGMT_LEVEL=DISABLED

testbuildmod.%: mod.%
	make $(MMARGS) MODE=$(MODE) -C $* testbuild DEPS_MNGMT_LEVEL=DISABLED

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

help:
	@grep "^## " $(MAKEFILE_LIST) | sed -e 's/^.*## //'

_extra_import_defs_=$(subst !,\n,$(extra_import_defs))
_extra_import_defs_:=$(subst $(_space_)!,\n,$(extra_import_defs))
_extra_import_defs_:=$(subst !,\n,$(_extra_import_defs_))
_extra_import_defs_:=$(subst $(_carriage_return_),\n,$(_extra_import_defs_))
$(eval _extra_import_defs_:=$(_extra_import_defs_))

DIST_FLATTEN_DIR:=dist/flatten/$(APPNAME)-$(VERSION)
INSTALL_TMP_DIR:=dist/install/$(APPNAME)-$(VERSION)
DIST_MODS:=$(filter-out $(NODISTMOD),$(MODULES_DEPS))

$(DIST_FLATTEN_DIR)/obj/compiled:
	@rm -rf $(DIST_FLATTEN_DIR)
	@mkdir -p $(@D)
	@$(ABS_PRINT_info) "Compilation of the project in mode: $(MODE)"
	@$(ABS_PRINT_debug) "Compilation of the modules: $(DIST_MODS)"
	@+make TRDIR=$(PRJROOT)/$(DIST_FLATTEN_DIR) MODE=$(MODE) $(patsubst %,mod.%,$(DIST_MODS))
	@$(ABS_PRINT_info) "Compilation of the project finished !"
	@touch $@

$(DIST_FLATTEN_DIR)/import.mk: $(DIST_FLATTEN_DIR)/obj/compiled
	@for modDir in $(EXPMOD); do \
	test ! -d $$modDir/include || cp -r $$modDir/include $(@D)/ ; \
	: ; \
	done
	@test -f export.mk && m4 -D__app__=$(APPNAME) -D__version__=$(VERSION) export.mk -D__uselib__="$(sort $(USELIB))" > $@.tmp || true
	@echo "# generated: ABS-$(__ABS_VERSION__) $(USER)@"`hostname`" "`date --rfc-3339 s` >> $@.tmp
	@test -f export.mk || printf '_app_$(APPNAME)_dir:=$$(dir $$(lastword $$(MAKEFILE_LIST)))\n\n' >> $@.tmp
	@test -f export.mk || echo '-include $$(wildcard $$(_app_$(APPNAME)_dir)/.abs/index_*.mk)' >> $@.tmp
	@test -f export.mk || printf '$$(eval $$(call extlib_import_template,$(APPNAME),$(VERSION),$(sort $(USELIB))))\n' >> $@.tmp
	@test -f export.mk || for mod in $(foreach mod,$(DIST_MODS),"$(mod)"); do \
		test ! -f $(@D)/obj/$$mod/module.mk || cat $(@D)/obj/$$mod/module.mk >> $@.tmp; \
	done
	@test -f export.mk || printf '$(subst $(_space_),\n,$(foreach mod,$(DIST_MODS),_module_$(APPNAME)_$(mod)_dir:=$$(_app_$(APPNAME)_dir)))\n\n' >> $@.tmp
	@test -f export.mk || printf '$(_extra_import_defs_)\n\n' >> $@.tmp
	@touch $(@D)/obj/extraFiles.ts
	@if [ -x extradist.sh ]; then VERSION=$(VERSION) APP=$(APPNAME) APPNAME=$(APPNAME) ./extradist.sh `dirname $@`; fi
	@find $(@D) -type f -cnewer $(@D)/obj/extraFiles.ts | grep -v $(@D)/obj | sed 's~$(@D)/~~g' | grep -E -v "$(subst *,.*,$(subst $(_space_),|,$(DIST_EXCLUDE)))" > $(@D)/.abs/content/$(APPNAME)__extra.filelist || true
	@rm -f $(@D)/obj/extraFiles.ts
	@test -d .svn && find dist -name ".svn" | xargs rm -rf || true
	@mv $@.tmp $@

DIST_ARCHIVE:=dist/$(APPNAME)-$(VERSION).$(ARCH).tar.gz
DISTINSTALL_BINARY:=dist/$(APPNAME)-$(VERSION).$(ARCH)-install.bin
KDISTINSTALL_BINARY:=dist/$(APPNAME)_lkm-$(VERSION)-$(KVERSION)-install.bin

$(DIST_ARCHIVE): $(DIST_FLATTEN_DIR)/import.mk
	@tar -czf $(DIST_ARCHIVE) -C dist/flatten $(DISTTARFLAGS) $(APPNAME)-$(VERSION)

##  - echoDID: displays package identifier
echoDID:
	@echo $(APPNAME)-$(VERSION).$(ARCH)

pubfile: $(FILE)
	scp $(FILE) $(DISTREPO)/$(ARCH)/`basename $(FILE)`

ifeq ($(MAKECMDGOALS),__installextlibs)

# this generate ABS_INCLUDE_MODS variable
PROJMODS=$(patsubst %,$(APPNAME)_%,$(MODULES_DEPS))
include $(patsubst %,$(MODULE_MK_DIR)/module_%.mk,$(PROJMODS))
# INCLUDE_INSTALL_MODS additionnals mods to include in the installation.
ABS_INCLUDE_MODS+=$(INCLUDE_INSTALL_MODS)
include $(foreach mod,$(INCLUDE_INSTALL_MODS),$(wildcard $(MODULE_MK_DIR)/module_$(mod).mk))
# Install external dependencies
INCLUDE_EXT_LIBS=$(sort $(filter-out $(PROJMODS),$(ABS_INCLUDE_MODS)))
INCLUDE_EXT_LIBS_MODULES=$(foreach lib,$(INCLUDE_EXT_LIBS),$(if $(_module_$(lib)_dir),$(lib)))
INCLUDE_EXT_MODS_TO_INSTALL=$(patsubst %,installExt.%,$(INCLUDE_EXT_LIBS_MODULES))
INCLUDE_EXT_LIBS_TO_INSTALL=$(patsubst %,installExtLib.%,$(filter-out $(INCLUDE_EXT_LIBS_MODULES),$(INCLUDE_EXT_LIBS)))

installExt.%:
	@$(ABS_PRINT_info) "  Processing external module $* ..."
	@modPath=$(_module_$*_dir) && test -z "$$modPath" || test ! -d $$modPath || test ! -f $(_module_$*_dir)/.abs/content/$*.filelist || (\
		cat $(_module_$*_dir)/.abs/content/$*.filelist | tar -C $$modPath/ -cf - -T - | tar -C $(INSTALL_TMP_DIR)/ -xf -)

installExtLib.%:
	@$(ABS_PRINT_info) "  Processing external library $* ..."
	@libPath=$(_app_$*_dir) && test -n "$$libPath" && test -d $$libPath && cp -rf $$libPath/* $(INSTALL_TMP_DIR)/ && chmod -R u+rw $(INSTALL_TMP_DIR) || true

# Advanced dependency management disabled: old way with all the libraries included in the binary
ifeq ($(ADV_DEPENDS_MANAGEMENT),false)
__installextlibs:
	@for lib in `ls $(DIST_FLATTEN_DIR)/extlib/ | fgrep -v cppunit-` ; do \
		$(ABS_PRINT_info) "  Processing $$lib..." ; \
		test -d $(DIST_FLATTEN_DIR)/extlib/$$lib && (tar -C $(DIST_FLATTEN_DIR)/extlib/$$lib -cf - $(DISTTARFLAGS) --exclude=import.mk --mode=755 . | tar -C $(INSTALL_TMP_DIR) -xf - ) || cp $(DIST_FLATTEN_DIR)/extlib/$$lib $(INSTALL_TMP_DIR)/lib ; \
		done

else # ifeq ($(ADV_DEPENDS_MANAGEMENT),false)
__installextlibs: $(INCLUDE_EXT_MODS_TO_INSTALL) $(INCLUDE_EXT_LIBS_TO_INSTALL)

endif # ifeq ($(ADV_DEPENDS_MANAGEMENT),false)

endif # ifeq ($(MAKECMDGOALS),__installextlibs)

$(INSTALL_TMP_DIR)/import.mk: $(DIST_FLATTEN_DIR)/import.mk
	@mkdir -p $(@D)
	@+make TRDIR=$(PRJROOT)/$(DIST_FLATTEN_DIR) MODE=$(MODE) -j1 __installextlibs
	@$(ABS_PRINT_info) "Copying file tree..."
	@tar -cf - $(patsubst %,--exclude %,obj extlib extlib.nodist import.mk) -C $(<D) . | tar -C $(@D) -xf -
	@$(ABS_PRINT_info)  "Copying dependencies..."
	@for lib in `ls $(EXTLIBDIR) | fgrep -v cppunit-` ; do \
	if [ ! -d $(EXTLIBDIR)/$$lib ]; then \
	$(ABS_PRINT_info) "  Processing $$lib..." ; \
	cp $(EXTLIBDIR)/$$lib $(@D)/lib ; \
	fi; \
	done
	@cp $< $@

##  - install [PREFIX=<install path>]: installs the application
.PHONY: install
install: $(DISTINSTALL_BINARY)
	@./$(DISTINSTALL_BINARY) install $(PREFIX)

$(DISTINSTALL_BINARY): $(INSTALL_TMP_DIR)/import.mk
	@tar -C $(<D)/../ -czf - $(DISTTARFLAGS) $(INSTALLTARFLAGS) $(APPNAME)-$(VERSION) > $@.tmp2
	@sed -e 's/__appname__/$(APPNAME)/g' $(ABSROOT)/core/install-template.sh |\
	sed -e 's/__version__/$(VERSION)/g' | \
	sed -e 's/__checksum__/'`md5sum $@.tmp2 | cut -f 1 -d ' '`'/g' | \
	sed -e 's~__post_install_patch_files__~$(POST_INSTALL_PATCH_FILES)~g' > "$@.tmp"
	@cat "$@.tmp2" >> "$@.tmp"
	@chmod +x "$@.tmp"
	@rm $@.tmp2
	@mv $@.tmp $@

##  - distinstall: builds installation package.
##  - kdistinstall: builds linux kernel modules installation package
##  - dist: creates binary package
ifeq ($(ACTIVATE_SANITIZER),true)
dist:
	@$(ABS_PRINT_warning) "Cannot execute dist target if ACTIVATE_SANITIZER=true"
	@false

distinstall:
	@$(ABS_PRINT_warning) "Cannot execute distinstall target if ACTIVATE_SANITIZER=true"
	@false

kdistinstall:
	@$(ABS_PRINT_warning) "Cannot execute kdistinstall target if ACTIVATE_SANITIZER=true"
	@false

else
dist: $(DIST_ARCHIVE)

distinstall: $(DISTINSTALL_BINARY)

kdistinstall: $(KDISTINSTALL_BINARY)

endif

$(KDISTINSTALL_BINARY): $(INSTALL_TMP_DIR)/import.mk
	tar -C $(INSTALL_TMP_DIR) $(DISTTARFLAGS) -cvzf "$@.tmp2" etc/ lib/
	sed -e 's/__app__/$(APPNAME)/g' $(ABSROOT)/core/kinstall-template.sh | sed -e 's/__version__/$(VERSION)/g' | sed -e 's/__kversion__/$(KVERSION)/g' > "$@.tmp"
	cat "$@.tmp2" >> "$@.tmp"
	chmod +x "$@.tmp"
	rm "$@.tmp2"
	@mv "$@.tmp" "$@"

pubdist: dist
	@$(ABS_PRINT_info)  "Publishing dist archive $(DIST_ARCHIVE) $(USER) on $(DISTREPO)"
ifneq ($(filter file://%,$(DISTREPO)),)
	cp $(DIST_ARCHIVE) $(patsubst file://%,%,$(DISTREPO))/$(ARCH)/$(APPNAME)-$(VERSION).$(ARCH).tar.gz
else
	@scp $(SCPFLAGS) $(DIST_ARCHIVE) $(DISTREPO)/$(ARCH)/$(APPNAME)-$(VERSION).$(ARCH).tar.gz
endif

pubinstall: distinstall
	@$(ABS_PRINT_info)  "Publishing dist archive $(DISTINSTALL_BINARY) $(USER) on $(DISTREPO)"
ifneq ($(filter file://%,$(DISTREPO)),)
	@cp $(DISTINSTALL_BINARY) $(patsubst file://%,%,$(DISTREPO))/$(ARCH)/$(APPNAME)-$(VERSION).$(ARCH)-install.bin
else
	@scp $(SCPFLAGS) $(DISTINSTALL_BINARY) $(DISTREPO)/$(ARCH)/$(APPNAME)-$(VERSION).$(ARCH)-install.bin
endif

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

ifneq ($(IMPORT_ABSMOD),)
include $(patsubst %,$(ABSROOT)/%/main.mk,$(IMPORT_ABSMOD))
endif

## --------------------------------------------------------------------------
## Configuration management services
##
## Variables
##  - BRANCH_VERSION: current branch identifier
BRANCH_VERSION:=$(VMAJOR).$(VMEDIUM)
##  - TAG_VERSION: current version identifier to be used for next tagging
TAG_VERSION:=$(BRANCH_VERSION).$(VMINOR)
##  - NEW_VERSION: next version  identifier after tagging.
NEW_VERSION:=$(BRANCH_VERSION).$(shell expr $(VMINOR) + 1)
##
##
## Targets:
##  - tag M="<msg>": create tag
##      <msg>: tag comment message
ifeq ($(M),)
tag:
	@$(ABS_PRINT_error) "Can't tag, comment message is missing."
	@$(ABS_PRINT_error) '    make tag M="<msg>"'
else
tag:
	@$(ABS_PRINT_info) "Tagging $(APPNAME) $(TAG_VERSION) ..."
	$(abs_scm_tag)
	@sed -i -e s/^VERSION=.*$$/VERSION=$(NEW_VERSION)/g app.cfg
	$(call abs_scm_commit,$(VISSUE) [tag switch] $(M))
	@$(ABS_PRINT_info) "# Tag set: $(APPNAME) $(TAG_VERSION)"
endif
##  - branch <X.Y> I=<issue> M="<msg>": create branch <APPNAME>-X.Y
##      <issue>: new branch tracking issue reference.
##      <msg>: branch creation comment message
ifeq ($(word 1,$(MAKECMDGOALS)),branch)
NEW_BRANCH=$(word 2,$(MAKECMDGOALS))
ifeq ($(NEW_BRANCH),)
branch:
	@$(ABS_PRINT_error) "Can't create branch, new branch spec is missing"
	@$(ABS_PRINT_error) "    make branch <X.Y> I=<issue> M='<msg>'"
else
$(NEW_BRANCH):
	@:
ifeq ($(I),)
branch:
	@$(ABS_PRINT_error) "Can't create branch $(APPNAME)-$(NEW_BRANCH), missing tracking issue."
	@$(ABS_PRINT_error) "    make branch <X.Y> I=<issue> M='<msg>'"
else ifeq ($(M),)
branch:
	@$(ABS_PRINT_error) "Can't create branch $(APPNAME)-$(NEW_BRANCH), missing comment message."
	@$(ABS_PRINT_error) "    make branch <X.Y> I=<issue> M='<msg>'"
else
branch:
	@$(ABS_PRINT_info) "Creating branch $(APPNAME)-$(NEW_BRANCH) from $(APPNAME)-$(VERSION)..."
	$(call abs_scm_branch)
endif # check param I and M
endif # check NEW_BRANCH
endif # branch target
## 
## --------------------------------------------------------------------
## Docker utilities.
##  Enable easy cross build on same hardware architecture for an alternate
##  OS distribution without setting up a huge VM.
## Targets:
##   - docker[.<target>] <image>
##     call make from current place binded in the provided docker image.
DOCKER_CMD?=docker

ifneq ($(filter docker%,$(word 1,$(MAKECMDGOALS))),)
## Variables:
DOCKER_IMAGE:=$(word 2,$(MAKECMDGOALS))
ifeq ($(DOCKER_IMAGE),)
docker.%:
	@$(ABS_PRINT_error) "argument missing: need a docker image name."
	@$(ABS_PRINT_error) "   make docker[.<target>] <image>"

else
DOCKER_TARGET:=$(TARGET)
DOCKER_ARGS+=--rm --hostname $(shell hostname).$(subst /,.,$(DOCKER_IMAGE))
DOCKER_WORKSPACE:=/home/$(USER)
# preliminary command to create user env in the container.
DOCKER_CREATEUSERENV:=echo $(USER):x:$(shell id -u):$(shell id -g)::$(DOCKER_WORKSPACE):/bin/bash >> /etc/passwd && chown $(USER) $(DOCKER_WORKSPACE) && echo $(USER):*:18464:0:99999:7::: >> /etc/shadow
# let the dockerized build open ssh session as the user from the host.
DOCKER_ARGS+=-v $(HOME)/.ssh:$(DOCKER_WORKSPACE)/.ssh
##  - DOCKER_WORKSPACE: workspace root dir inside the container ot use for the
##    build. Caution it shall be writeable for the uid/gid calling make, since
##    it is set from current user to ensure proper access to project source tree
##    that is bind into the container as 
##    $(DOCKER_WORKSPACE)/$(APPNAME)-$(VERSION).
##    Default is set to /tmp that is a quite standard place world writable.
DOCKER_WDIR:=$(DOCKER_WORKSPACE)/$(APPNAME)-$(VERSION)
DOCKER_ARGS+=-v $(PRJROOT):$(DOCKER_WDIR)

.PHONY: docker.%
docker.%:
	@$(ABS_PRINT_info) "Running build with target $* from docker image $(DOCKER_IMAGE)"
	@# the () are needed to avoid the quit of container at the end of execution of some commands.
	@$(DOCKER_CMD) run $(DOCKER_ARGS) $(DOCKER_IMAGE) bash -c "($(DOCKER_CREATEUSERENV) && su - $(USER) -c 'cd $(DOCKER_WDIR) && make $(patsubst docker.%,%,$@) $(MAKEARGS)')"

dockershell:
	@$(ABS_PRINT_info) "Starting shell from docker image $(DOCKER_IMAGE)"
	@$(DOCKER_CMD) run $(DOCKER_ARGS) -it $(DOCKER_IMAGE) bash -c "($(DOCKER_CREATEUSERENV) && su - $(USER))"

.PHONY: $(DOCKER_IMAGE)
$(DOCKER_IMAGE):
	@:

endif # if DOCKER_IMAGE
else
.PHONY: docker.%
docker.%:
	@$(ABS_PRINT_warning) "docker target ignored, should be used first to run build from docker image."
	@$(ABS_PRINT_warning) "   make docker[.<target>] <image>"

endif # docker as first target.

.PHONY: docker
docker: docker.all

# update bootstrap makefile if needed.
ifneq ($(PRESERVEMAKEFILE),true)
Makefile: $(ABSROOT)/core/bootstrap.mk
	@$(ABS_PRINT_info) "Updating bootstrap makefile."
	@cp $^ $@
endif

## 
## --------------------------------------------------------------------
## ABS management utilities.
##   - cleanabs: clean abs workdir (will remove all files cached by abs and abs
##     itself). Does not make any change inside your project tree.
cleanabs:
	@$(ABS_PRINT_info) "Setting write permissions to $(ABSWS)..."
	@chmod -R u+w $(ABSWS) 2> /dev/null
	@$(ABS_PRINT_info) "Cleaning ABS files and cache $(ABSWS)..."
	@rm -rf $(ABSWS)/extlib $(ABSWS)/cache $(ABSROOT)
	@$(ABS_PRINT_info) "ABS cleaning completed."

absclean: cleanabs

