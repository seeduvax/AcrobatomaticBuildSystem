## 
## --------------------------------------------------------------------------
## Distribution production targets
## --------------------------------------------------------------------------
##

_extra_import_defs_=$(subst !,\n,$(extra_import_defs))
_extra_import_defs_:=$(subst $(_space_)!,\n,$(extra_import_defs))
_extra_import_defs_:=$(subst !,\n,$(_extra_import_defs_))
_extra_import_defs_:=$(subst $(_carriage_return_),\n,$(_extra_import_defs_))
$(eval _extra_import_defs_:=$(_extra_import_defs_))

##  - cleandist: remove the dist directory
cleandist:
	@$(ABS_PRINT_info) "Cleaning dist ..."
	@$(ABS_PRINT_info) "Changing permissions of dist"
	@-test ! -d dist || chmod -R u+w dist 2> /dev/null
	@$(ABS_PRINT_info) "Removing dist"
	@rm -rf dist

DIST_FLATTEN_DIR:=dist/flatten/$(APPNAME)-$(VERSION)
INSTALL_TMP_DIR:=dist/install/$(APPNAME)-$(VERSION)
DIST_MODS:=$(filter-out $(NODISTMOD),$(MODULES_DEPS))

$(DIST_FLATTEN_DIR)/obj/compiled:
	@rm -rf $(DIST_FLATTEN_DIR)
	@mkdir -p $(@D)
	@$(ABS_PRINT_info) "Compilation of the project in mode: $(MODE)"
	@$(ABS_PRINT_debug) "Compilation of the modules: $(DIST_MODS)"
	@+make TRDIR=$(PRJROOT)/$(DIST_FLATTEN_DIR) MODE=$(MODE) NOBUILD="$(NOBUILD)" $(patsubst %,$(PRJROOT)/$(DIST_FLATTEN_DIR)/obj/%/.done,$(DIST_MODS))
	@$(ABS_PRINT_info) "Compilation of the project finished !"
	@touch $@

$(DIST_FLATTEN_DIR)/import.mk: $(DIST_FLATTEN_DIR)/obj/compiled
	@for modDir in $(EXPMOD); do \
	test ! -d $$modDir/include || cp -r $$modDir/include $(@D)/ ; \
	: ; \
	done
	@test -f export.mk && m4 -D__app__=$(APPNAME) -D__version__=$(VERSION) export.mk -D__uselib__="$(sort $(USELIB))" > $@.tmp || true
	@echo "# generated: ABS-$(__ABS_VERSION__) $(USER)@"`hostname`" "`$(TRACE_DATE_CMD)` >> $@.tmp
	@test -f export.mk || printf '_app_$(APPNAME)_dir:=$$(dir $$(lastword $$(MAKEFILE_LIST)))\n\n' >> $@.tmp
	@test -f export.mk || echo '-include $$(wildcard $$(_app_$(APPNAME)_dir)/.abs/index_*.mk)' >> $@.tmp
	@test -f export.mk || printf '$$(eval $$(call extlib_import_template,$(APPNAME),$(VERSION),$(sort $(USELIB))))\n' >> $@.tmp
	@test -f export.mk || printf '$(foreach mod,$(sort $(DIST_MODS)),\n_module_$(APPNAME)_$(mod)_depends:=$(_module_$(APPNAME)_$(mod)_depends))\n' >> $@.tmp
	@test -f export.mk || printf '$(subst $(_space_),\n,$(foreach mod,$(sort $(DIST_MODS)) _extra,_module_$(APPNAME)_$(mod)_dir:=$$(_app_$(APPNAME)_dir)))\n\n' >> $@.tmp
	@test -f export.mk || printf '$(_extra_import_defs_)\n' >> $@.tmp
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


ifeq ($(MAKECMDGOALS),__installextlibs)

# needed external modules and libs retreiving
PROJMODS=$(patsubst %,$(APPNAME)_%,$(DIST_MODS))
include $(patsubst %,$(DIST_FLATTEN_DIR)/obj/%/moddeps.mk,$(DIST_MODS))
# INCLUDE_INSTALL_MODS additionnals external mods to include in the installation.
NEEDED_MODS=$(filter-out $(PROJMODS),$(sort $(foreach dmod,$(DIST_MODS),$(_module_$(APPNAME)_$(dmod)_depends)) $(foreach dmod,$(INCLUDE_INSTALL_MODS),$(_module_$(dmod)_depends)) $(INCLUDE_INSTALL_MODS)))
# Install external dependencies
# Use _dir variable because _depends can be empty
INCLUDE_EXT_MODULES:=$(sort $(foreach mod,$(NEEDED_MODS),$(if $(_module_$(mod)_dir),$(mod),)))
INCLUDE_EXT_LIBS:=$(sort $(foreach mod,$(NEEDED_MODS),$(if $(_module_$(mod)_dir),,$(mod))))
INCLUDE_EXT_MODS_TO_INSTALL=$(patsubst %,installExt.%,$(INCLUDE_EXT_MODULES))
INCLUDE_EXT_LIBS_TO_INSTALL=$(patsubst %,installExtLib.%,$(INCLUDE_EXT_LIBS))

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
	@test ! -d $(DIST_FLATTEN_DIR)/extlib || for lib in `ls $(DIST_FLATTEN_DIR)/extlib | fgrep -v cppunit-` ; do \
	if [ ! -d $(DIST_FLATTEN_DIR)/extlib/$$lib ]; then \
	$(ABS_PRINT_info) "  Processing $$lib..." ; \
	cp $(DIST_FLATTEN_DIR)/extlib/$$lib $(@D)/lib ; \
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

$(KDISTINSTALL_BINARY): $(DIST_FLATTEN_DIR)/import.mk
	tar -C $(DIST_FLATTEN_DIR) $(DISTTARFLAGS) -cvzf "$@.tmp2" etc/ lib/
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
