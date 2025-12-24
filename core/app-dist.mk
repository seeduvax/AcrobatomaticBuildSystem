## 
## --------------------------------------------------------------------------
## Distribution production targets
## --------------------------------------------------------------------------
## Variables:
##  - PUBLISH_TO_APP_LEVEL:
##       true: publish to $(DISTREPO)/$(APPNAME) directory
##       false: publish to $(DISTREPO)
## 
## Targets
##  - cleandist: remove the dist directory
##  - install [PREFIX=<install path>]: installs the application
##  - distinstall: builds installation package.
##  - kdistinstall: builds linux kernel modules installation package
##  - dist: creates binary package
##  - pubdist: publish dist package
##  - cachedist: record dist package into local abs packages cache.
##  - pubinstall: publish install package

PUBLISH_TO_APP_LEVEL?=false

_extra_import_defs_=$(subst !,\n,$(extra_import_defs))
_extra_import_defs_:=$(subst $(_space_)!,\n,$(extra_import_defs))
_extra_import_defs_:=$(subst !,\n,$(_extra_import_defs_))
_extra_import_defs_:=$(subst $(_carriage_return_),\n,$(_extra_import_defs_))
$(eval _extra_import_defs_:=$(_extra_import_defs_))

INSTALL_DIST_DIR:=dist/install/$(APPNAME)-$(VERSION)
DIST_MODS:=$(filter-out $(NODISTMOD),$(MODULES_DEPS))
# needed external modules and libs retreiving
DIST_PROJ_MODS=$(patsubst %,$(APPNAME)_%,$(DIST_MODS))
MODULES_DIST_TARGETS:=$(patsubst %,$(TR_DIST_DIR)/obj/%/.done,$(DIST_MODS))

DIST_ARCHIVE:=dist/$(APPNAME)-$(VERSION).$(ARCH).tar.gz
DISTINSTALL_BINARY:=dist/$(APPNAME)-$(VERSION).$(ARCH)-install.bin
KDISTINSTALL_BINARY:=dist/$(APPNAME)_lkm-$(VERSION)-$(KVERSION)-install.bin

# INCLUDE_INSTALL_MODS additionnals external mods to include in the installation.
NEEDED_MODS=$(filter-out $(DIST_PROJ_MODS),$(call getDependenciesByTransitivity,$(INCLUDE_INSTALL_MODS) $(DIST_PROJ_MODS)))
INCLUDE_EXT_MODULES=$(foreach mod,$(NEEDED_MODS),$(if $(_module_$(mod)_dir),$(mod),))
INCLUDE_EXT_LIBS=$(sort $(foreach mod,$(NEEDED_MODS),$(if $(_module_$(mod)_dir),,$(mod))))

ifneq ($(TRDIR),$(TR_DIST_DIR))
# compile first to have the .distinfo files available
$(TR_DIST_DIR)/obj/.compiled:
	@+make $(MODULES_DIST_TARGETS) TRDIR=$(TR_DIST_DIR) MODE=$(MODE) DIST_COMPILE_MODE=true
	@touch $@

$(TR_DIST_DIR)/import.mk: $(TR_DIST_DIR)/obj/.compiled
	@+make $@ TRDIR=$(TR_DIST_DIR) MODE=$(MODE)

$(INSTALL_DIST_DIR)/import.mk: $(TR_DIST_DIR)/obj/.compiled
	@+make $@ TRDIR=$(TR_DIST_DIR) MODE=$(MODE) -j1

else #ifneq ($(TRDIR),$(TR_DIST_DIR))

DIST_MODS_WITH_USELIBS=$(foreach mod,$(sort $(DIST_MODS)),$(if $(_module_$(APPNAME)_$(mod)_uselib),$(mod)))
EXPMOD_INCLUDES_DIR=$(wildcard $(patsubst %,%/include,$(EXPMOD)))

ifneq ($(DIST_COMPILE_MODE),true)
# include .distinfo.mk needed for import.mk generation
# use wildcard because some files doesn't exists 
include $(wildcard $(patsubst %,$(TRDIR)/obj/%/$(DISTINFO_FILENAME),$(DIST_MODS)))
# get external libs now because need uselib information from .distinfo.mk
$(eval $(call extlib_updates_deps))
endif

# Install external dependencies
INCLUDE_EXT_MODS_TO_INSTALL=$(patsubst %,installExt.%,$(INCLUDE_EXT_MODULES))
INCLUDE_EXT_LIBS_TO_INSTALL=$(patsubst %,installExtLib.%,$(INCLUDE_EXT_LIBS))


$(TRDIR)/import.mk: $(MODULES_DIST_TARGETS)
	@$(if $(EXPMOD_INCLUDES_DIR),cp -r $(EXPMOD_INCLUDES_DIR) $(@D))
	@test -f export.mk && m4 -D__app__=$(APPNAME) -D__version__=$(VERSION) export.mk -D__uselib__="$(sort $(USELIB))" > $@.tmp || true
	@echo "# generated: ABS-$(__ABS_VERSION__) $(USER)@"`hostname`" "`$(TRACE_DATE_CMD)` >> $@.tmp
	@test -f export.mk || printf '_app_$(APPNAME)_dir:=$$(dir $$(lastword $$(MAKEFILE_LIST)))\n\n' >> $@.tmp
	@test -f export.mk || printf '_app_$(APPNAME)_version:=$(VERSION)\n' >> $@.tmp
	@test -f export.mk || printf '_app_$(APPNAME)_uselib:=$(sort $(USELIB))\n' >> $@.tmp
	@test -f export.mk || printf '_app_$(APPNAME)_modules:=$(sort $(DIST_MODS))\n' >> $@.tmp
	@test -f export.mk || printf '$(foreach mod,$(sort $(DIST_MODS_WITH_USELIBS)),\n_module_$(APPNAME)_$(mod)_uselib:=$(_module_$(APPNAME)_$(mod)_uselib))\n' >> $@.tmp
	@test -f export.mk || printf '$(foreach mod,$(sort $(DIST_MODS)),$(if $(_module_$(APPNAME)_$(mod)_depends),\n_module_$(APPNAME)_$(mod)_depends:=$(_module_$(APPNAME)_$(mod)_depends)))\n' >> $@.tmp
	@test -f export.mk || printf '$(foreach mod,$(sort $(DIST_MODS)) _extra,\n_module_$(APPNAME)_$(mod)_dir:=$$(_app_$(APPNAME)_dir))\n' >> $@.tmp
	@test -f export.mk || printf '_app_$(APPNAME)_alluselib:=$$(sort $$(_app_$(APPNAME)_uselib) $(foreach mod,$(sort $(DIST_MODS_WITH_USELIBS)),$$(_module_$(APPNAME)_$(mod)_uselib)))\n\n' >> $@.tmp
	@test -f export.mk || echo '-include $$(wildcard $$(_app_$(APPNAME)_dir)/.abs/index_*.mk)' >> $@.tmp
	@test -f export.mk || printf '$$(eval $$(call extlib_import_template,$(APPNAME),$$(_app_$(APPNAME)_version),$$(_app_$(APPNAME)_alluselib)))\n\n' >> $@.tmp
	@test -f export.mk || printf '$(_extra_import_defs_)\n' >> $@.tmp
	@# remove spaces at the end of each lines (due to foreach executions).
	@test -f export.mk || sed -i -E 's/ *$$//g' $@.tmp
	@touch $(@D)/obj/extraFiles.ts
	@if [ -x extradist.sh ]; then VERSION=$(VERSION) APP=$(APPNAME) APPNAME=$(APPNAME) ./extradist.sh `dirname $@`; fi
	@mkdir -p $(@D)/.abs/content
	@find $(@D) -type f -cnewer $(@D)/obj/extraFiles.ts | grep -v $(@D)/obj | sed 's~$(@D)/~~g' | grep -E -v "$(subst *,.*,$(subst $(_space_),|,$(DIST_EXCLUDE)))" > $(@D)/.abs/content/$(APPNAME)__extra.filelist || true
	@rm -f $(@D)/obj/extraFiles.ts
	@test -d .svn && find dist -name ".svn" | xargs rm -rf || true
	@mv $@.tmp $@
	
# Advanced dependency management disabled: old way with all the libraries included in the binary
ifeq ($(ADV_DEPENDS_MANAGEMENT),false)
$(TRDIR)/obj/.libsInstalled: $(TRDIR)/import.mk
	@for lib in `ls $(TRDIR)/extlib/ | fgrep -v cppunit-` ; do \
		$(ABS_PRINT_info) "  Processing $$lib..." ; \
		test -d $(TRDIR)/extlib/$$lib && (tar -C $(TRDIR)/extlib/$$lib -cf - $(DISTTARFLAGS) --exclude=import.mk --mode=755 . | tar -C $(INSTALL_DIST_DIR) -xf - ) || cp $(TRDIR)/extlib/$$lib $(INSTALL_DIST_DIR)/lib ; \
		done
	@touch $@
else # ifeq ($(ADV_DEPENDS_MANAGEMENT),false)

installExt.%: $(TRDIR)/import.mk
	@mkdir -p $(INSTALL_DIST_DIR)
	@$(ABS_PRINT_info) "  Processing external module $* $(if $(_module_$*_dir),,(Not found !)) ..."
	@$(call writeToBuildLogs,Processing external module $*)
	@modPath=$(_module_$*_dir) && test -z "$$modPath" || test ! -d $$modPath || test ! -f $$modPath/.abs/content/$*.filelist || (\
		cat $$modPath/.abs/content/$*.filelist | tar -C $$modPath/ -cf - -T - | tar -C $(INSTALL_DIST_DIR)/ -xf -)

installExtLib.%: $(TRDIR)/import.mk
	@mkdir -p $(INSTALL_DIST_DIR)
	@$(ABS_PRINT_info) "  Processing external library $* $(if $(_app_$*_dir),,(Not found !)) ..."
	@$(call writeToBuildLogs,Processing external library $*)
	@libPath=$(_app_$*_dir) && test -n "$$libPath" && test -d $$libPath && cp -rf $$libPath/* $(INSTALL_DIST_DIR)/ && chmod -R u+rw $(INSTALL_DIST_DIR) || true


$(TRDIR)/obj/.libsInstalled:  $(INCLUDE_EXT_MODS_TO_INSTALL) $(INCLUDE_EXT_LIBS_TO_INSTALL)
	@touch $@

endif # ifeq ($(ADV_DEPENDS_MANAGEMENT),false)

$(INSTALL_DIST_DIR)/import.mk: $(TRDIR)/obj/.libsInstalled
	@mkdir -p $(@D)
	@$(ABS_PRINT_info) "Copying file tree..."
	@tar -cf - $(patsubst %,--exclude %,obj extlib extlib.nodist import.mk) -C $(TRDIR) . | tar -C $(@D) -xf -
	@$(ABS_PRINT_info)  "Copying dependencies..."
	@# copy of external libs that are not in directories (ex: jar files)
	@test ! -d $(TRDIR)/extlib || for lib in `ls $(TRDIR)/extlib | fgrep -v cppunit-` ; do \
	if [ ! -d $(TRDIR)/extlib/$$lib ]; then \
	$(ABS_PRINT_info) "  Processing $$lib..." ; \
	cp $(TRDIR)/extlib/$$lib $(@D)/lib ; \
	fi; \
	done
	@cp $< $@

endif #ifneq ($(TRDIR),$(TR_DIST_DIR))

$(DIST_ARCHIVE): $(TR_DIST_DIR)/import.mk
	@tar -czf $(DIST_ARCHIVE) -C $(DIST_FLATTEN_DIR) $(DISTTARFLAGS) $(APPNAME)-$(VERSION)
	@$(ABS_PRINT_info) "Archive $@ created"

$(DISTINSTALL_BINARY): $(INSTALL_DIST_DIR)/import.mk
	@tar -C $(<D)/../ -czf - $(DISTTARFLAGS) $(INSTALLTARFLAGS) $(APPNAME)-$(VERSION) > $@.tmp2
	@sed -e 's/__appname__/$(APPNAME)/g' \
		-e 's/__version__/$(VERSION)/g' \
		-e 's/__checksum__/'`md5sum $@.tmp2 | cut -f 1 -d ' '`'/g' \
		-e 's~__post_install_patch_files__~$(POST_INSTALL_PATCH_FILES)~g' \
		$(ABSROOT)/core/install-template.sh > "$@.tmp"
	@cat "$@.tmp2" >> "$@.tmp"
	@chmod +x "$@.tmp"
	@rm $@.tmp2
	@mv $@.tmp $@
	@$(ABS_PRINT_info) "Binary installer $@ created"

.PHONY: install
install: $(DISTINSTALL_BINARY)
	@./$(DISTINSTALL_BINARY) install $(PREFIX)

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

$(KDISTINSTALL_BINARY): $(TR_DIST_DIR)/import.mk
	tar -C $(TR_DIST_DIR) $(DISTTARFLAGS) -cvzf "$@.tmp2" etc/ lib/
	sed -e 's/__app__/$(APPNAME)/g' \
		-e 's/__version__/$(VERSION)/g' \
		-e 's/__kversion__/$(KVERSION)/g' \
		$(ABSROOT)/core/kinstall-template.sh > "$@.tmp"
	cat "$@.tmp2" >> "$@.tmp"
	chmod +x "$@.tmp"
	rm "$@.tmp2"
	@mv "$@.tmp" "$@"

ifeq ($(PUBLISH_TO_APP_LEVEL),true)
PROJ_DIST_REPO=$(DISTREPO)/$(ARCH)/$(APPNAME)
else
PROJ_DIST_REPO=$(DISTREPO)/$(ARCH)
endif

cleandist:
	@$(ABS_PRINT_info) "Cleaning dist ..."
	@$(ABS_PRINT_info) "Changing permissions of dist"
	@-test ! -d dist || chmod -R u+w dist 2> /dev/null
	@$(ABS_PRINT_info) "Removing dist"
	@rm -rf dist

ifndef pubdist-cmd
ifneq ($(filter file://%,$(PROJ_DIST_REPO)),)
define pubdist-cmd
	@$(ABS_PRINT_info)  "Publishing dist archive $(DIST_ARCHIVE) $(USER) on $(DISTREPO)"
	@outputFile="$(patsubst file://%,%,$(PROJ_DIST_REPO))/$(APPNAME)-$(VERSION).$(ARCH).tar.gz" && \
		mkdir -p `dirname $$outputFile` && cp $1 $$outputFile
endef
else
define pubdist-cmd
	@$(ABS_PRINT_info)  "Publishing dist archive $(DIST_ARCHIVE) $(USER) on $(DISTREPO)"
	@ssh $(SSHFLAGS) $(word 1,$(subst :, ,$(PROJ_DIST_REPO))) -C "mkdir -p $(word 2,$(subst :, ,$(PROJ_DIST_REPO)))"
	@scp $(SCPFLAGS) $1 $(PROJ_DIST_REPO)/$(APPNAME)-$(VERSION).$(ARCH).tar.gz
endef
endif
endif



pubdist: dist
	$(call pubdist-cmd,$(DIST_ARCHIVE))

cachedist: dist
	@$(ABS_PRINT_info) "Storing dist archive $(DIST_ARCHIVE) into local ABS cache"
	@mkdir -p $(ABS_CACHE)/$(ARCH)
	@mv $(DIST_ARCHIVE) $(ABS_CACHE)/$(ARCH)/

pubinstall: distinstall
	@$(ABS_PRINT_info)  "Publishing install binary $(DISTINSTALL_BINARY) $(USER) on $(DISTREPO)"
ifneq ($(filter file://%,$(PROJ_DIST_REPO)),)
	@outputFile="$(patsubst file://%,%,$(PROJ_DIST_REPO))/$(APPNAME)-$(VERSION).$(ARCH)-install.bin" && \
		mkdir -p `dirname $$outputFile` && cp $(DISTINSTALL_BINARY) $$outputFile
else
	@ssh $(SSHFLAGS) $(word 1,$(subst :, ,$(PROJ_DIST_REPO))) -C "mkdir -p $(word 2,$(subst :, ,$(PROJ_DIST_REPO)))"
	@scp $(SCPFLAGS) $(DISTINSTALL_BINARY) $(PROJ_DIST_REPO)/$(APPNAME)-$(VERSION).$(ARCH)-install.bin
endif
