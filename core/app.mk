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

##  - DIST_EXCLUDE: pattern for files to be excluded on packaging.
##      (default: share/*/tex)
DIST_EXCLUDE:=share/*/tex
##  - LIGHT_INSTALLER: when set to 1, add share/*/doxygen and include to the 
##      list of file to exclude on packaging.
ifeq ($(LIGHT_INSTALLER),1)
INSTALLTAR_EXCLUDE:=share/*/doxygen include
endif
##  - DISTTARFLAGS: arguments to add to tar command when packing files on dist
##      and distinstall target.
DISTTARFLAGS+=$(patsubst %,--exclude=%,$(DIST_EXCLUDE))

##  - INSTALLTARFLAGS: arguments to add to tar command when packing files on distinstall target.
INSTALLTARFLAGS+=$(patsubst %,--exclude=%,$(INSTALLTAR_EXCLUDE))

ifeq ($(MODULES),)
# search for module only if not explicitely defined from app.cfg.
MODULES_DEPS:=$(filter-out $(patsubst %,mod.%,$(NOBUILD)),$(patsubst %/Makefile,mod.%,$(wildcard */Makefile)))
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

$(TRDIR)/obj/.moddeps.mk:
	@$(ABS_PRINT_info) "Gererating module dependencies file."
	@mkdir -p $(@D)
ifeq ($(wildcard $(BUILDROOT)/extlib),)
	@ln -sf $(ABSWS)/extlib $(BUILDROOT)/extlib
endif
	@for mod in $(patsubst mod.%,%,$(MODULES_DEPS)) ; do \
	for element in mod testmod testbuildmod valgrindtestmod; do \
	echo "$$element.$$mod:: "'$$(patsubst %,'`echo $$element`.%','`grep 'USE\(LK\)*MOD=' $$mod/module.cfg | cut -d '=' -f 2`")" >> $@ ; \
	echo >> $@ ; \
	done; \
	done

mod.%::
	make $(MMARGS) -C $* DEEPDEP=0

include $(TRDIR)/obj/.moddeps.mk

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

_extra_import_defs_=$(subst !,\n,$(shell echo '$(extra_import_defs)'))

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


DISTTAR:=tar cvzf dist/$(APPNAME)-$(VERSION).$(ARCH).tar.gz -C dist --exclude obj --exclude extlib --exclude extlib.nodist $(DISTTARFLAGS) $(APPNAME)-$(VERSION)

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
	@$(ABS_PRINT_info) "Copying file tree..."
	@tar -cf - dist/$(APPNAME)-$(VERSION) $(patsubst %,--exclude dist/$(APPNAME)-$(VERSION)/%,obj extlib extlib.nodist) | tar -C $(PREFIX) --strip-components=2 -xf -
	@$(ABS_PRINT_info)  "Copying dependancies..."
	@for lib in `ls dist/$(APPNAME)-$(VERSION)/extlib/ | fgrep -v cppunit-` ; do \
	$(ABS_PRINT_info) "  Processing $$lib..." ; \
	test -d dist/$(APPNAME)-$(VERSION)/extlib/$$lib && chmod -R +rwX dist && ( tar -C dist/$(APPNAME)-$(VERSION)/extlib/$$lib -cf - include lib lib64 etc bin sbin share | tar -C $(PREFIX) -xf - ) || cp dist/$(APPNAME)-$(VERSION)/extlib/$$lib $(PREFIX)/lib ; \
	done

dist/$(APPNAME)-$(VERSION).$(ARCH)-install.bin:
	@make PREFIX=tmp/$(APPNAME)-$(VERSION) install
	@tar -C tmp -cvzf tmp/arch.tar.gz $(DISTTARFLAGS) $(INSTALLTARFLAGS) $(APPNAME)-$(VERSION)/
	@sed -e 's/__appname__/$(APPNAME)/g' $(ABSROOT)/core/install-template.sh |\
	sed -e 's/__version__/$(VERSION)/g' | \
	sed -e 's~__post_install_patch_files__~$(POST_INSTALL_PATCH_FILES)~g' > "$@"
	cat tmp/arch.tar.gz >> "$@"
	chmod +x "$@"

##  - distinstall: builds installation package.
distinstall: dist/$(APPNAME)-$(VERSION).$(ARCH)-install.bin

##  - kdistinstall: builds linux kernel modules installation package
kdistinstall: dist/$(APPNAME)_lkm-$(VERSION)-$(KVERSION)-install.bin

KMODULES:=$(filter-out $(patsubst %,mod.%,$(NOBUILD)),$(patsubst %,mod.%,$(shell ls | grep _lkm)))
dist/$(APPNAME)_lkm-$(VERSION)-$(KVERSION)-install.bin:
	@make TRDIR=$$PWD/dist/$(APPNAME)-$(VERSION) MODE=release $(KMODULES)
	tar -C dist/$(APPNAME)-$(VERSION) $(DISTTARFLAGS) -cvzf dist/arch.tar.gz etc/ lib/
	sed -e 's/__app__/$(APPNAME)/g' $(ABSROOT)/core/kinstall-template.sh | sed -e 's/__version__/$(VERSION)/g' | sed -e 's/__kversion__/$(KVERSION)/g' > "$@"
	cat dist/arch.tar.gz >> "$@"
	chmod +x "$@"
	rm dist/arch.tar.gz

pubdist: dist/$(APPNAME)-$(VERSION).$(ARCH).tar.gz
	@$(ABS_PRINT_info)  "Publishing dist archive $^ $(USER) on $(DISTREPO)"
	@scp $^ $(DISTREPO)/$(ARCH)/$(APPNAME)-$(VERSION).$(ARCH).tar.gz
ifneq ($(RELEASE_IDENTIFIER),)
	@ssh $(DISTHOST) rm -rf $(patsubst $(DISTHOST):%,%,$(DISTREPO))/$(ARCH)/$(APPNAME)-$(RELEASE_IDENTIFIER).$(ARCH).tar.gz
	@ssh $(DISTHOST) ln -sf $(APPNAME)-$(VERSION).$(ARCH).tar.gz $(patsubst $(DISTHOST):%,%,$(DISTREPO))/$(ARCH)/$(APPNAME)-$(RELEASE_IDENTIFIER).$(ARCH).tar.gz
endif

pubinstall: dist/$(APPNAME)-$(VERSION).$(ARCH)-install.bin
	@$(ABS_PRINT_info)  "Publishing dist archive $^ $(USER) on $(DISTREPO)"
	@scp $^ $(DISTREPO)/$(ARCH)/$(APPNAME)-$(VERSION).$(ARCH)-install.bin

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
NEW_BRANCH=$(word 2,$(MAKCMDGOALS))
ifeq ($(NEW_BRANCH),)
branch:
	@$(ABS_PRINT_error) "Can't crate branch, new branch spec is missing"
	@$(ABS_PRINT_error) "    make branch <X.Y> I=<issue> M='<msg>'"
else
NEW_BRANCH:
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
DOCKER_CREATEUSERENV:=echo $(USER):x:$(shell id -u):$(shell id -g)::$(DOCKER_WORKSPACE):/bin/bash >> /etc/passwd && chown $(USER) $(DOCKER_WORKSPACE)
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
	@docker run $(DOCKER_ARGS) $(DOCKER_IMAGE) bash -c "($(DOCKER_CREATEUSERENV) && su - $(USER) -c 'cd $(DOCKER_WDIR) && make $(patsubst docker.%,%,$@)' $(MAKEARGS))"

dockershell:
	@$(ABS_PRINT_info) "Starting shell from docker image $(DOCKER_IMAGE)"
	@docker run $(DOCKER_ARGS) -it $(DOCKER_IMAGE) bash -c "($(DOCKER_CREATEUSERENV) && su - $(USER))"

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
	@rm -rf $(ABSWS)
	@$(ABS_PRINT_info) "$(ABSWS) removed."
