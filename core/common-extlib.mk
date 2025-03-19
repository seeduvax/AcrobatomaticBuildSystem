## 
## ------------------------------------------------------------------------
## Dependencies management
## ------------------------------------------------------------------------
EXTLIBS_GENE_FILES_DIR=$(PRJOBJDIR)/_extlibs
ALL_INCLUDED_FILE=$(EXTLIBS_GENE_FILES_DIR)/.allExtDepsIncluded

# replace the | by - in libs specifications.
USELIB_FOR_PATH=$(subst |,-,$(USELIB))

# MAP to get version of lib with | separator.
# This permit to correctly identify version even if lib have a '-' in its name
# ex: cppunit-1.14.0 => cppunit|1.14.0
define getMapListLibVersioned
$(foreach lib,$1,$(subst |,-,$(lib))|$(lib))
endef

# macro to get lib name with version using | caractere.
# 1: lib name with '-'
# 2: list of lib 
define getLibWithBar
$(patsubst $1|%,%,$(if $(filter $1|%,$(call getMapListLibVersioned,$2)),$(filter $1|%,$(call getMapListLibVersioned,$2)),$1))
endef

# macro to get the lib name from <libname>-<version> or <libname>|<version>
# 1: the name of lib with version.
define getLibNameFromVersioned
$(if $(findstring |,$1),$(word 1,$(subst |, ,$1)),$(word 1,$(subst -, ,$1)))
endef

# macro to get the lib name from lib with version.
# This macro use libs in list to get the real name of lib
#  if the list contains the lib with '|'
# 1: the name of lib with version
# 2: the list of libs
define findLibNameFromVersioned
$(call getLibNameFromVersioned,$(call getLibWithBar,$1,$2))
endef

# macro to get lib from the name of the archive
# 1: archive name (ex: cppunit-1.14.0.$(ARCH).tar.gz)
# return the name of lib (ex: cppunit-1.14.0)
define getLibFromArchiveName
$(strip $(patsubst %.$(ARCH).tar.gz,%,$(filter %.$(ARCH).tar.gz,$1))\
$(patsubst %.noarch.tar.gz,%,$(filter %.noarch.tar.gz,$1)))
endef

# macro to get lib name from the name of the archive
# 1: archive name (ex: cppunit-1.14.0.$(ARCH).tar.gz)
# 2: list of libs
define getLibNameFromArchiveName
$(call findLibNameFromVersioned,$(call getLibFromArchiveName,$1),$2)
endef

# mecro to get the list from a list using its name.
# 1: name of the lib
# 2: list of libs
define getLibWithLibName
$(filter $1|% $1-%,$2)
endef

# macro to test if a lib has already been loaded.
# 1: lib name with version
# 2: list of libs
define isLibInList
$(filter $(subst |,-,$1),$(subst |,-,$2))
endef

# macro to test if a lib has already been loaded (only by name).
# 1: lib name with version
# 2: list of libs
define isLibInListByName
$(filter $(call getLibNameFromVersioned,$1)-%,$(subst |,-,$2))
endef

ABSWS_EXTLIBDIR=$(ABSWS)/extlib/$(ARCH)
ABSWS_NA_EXTLIBDIR=$(ABSWS)/extlib/noarch
ABSWS_NDEXTLIBDIR=$(ABSWS_EXTLIBDIR).nodist
ABSWS_NDNA_EXTLIBDIR=$(ABSWS_NA_EXTLIBDIR).nodist

ifeq ($(TRDIR),$(BUILDROOT)/$(ARCH)/$(MODE))
EXTLIBDIR?=$(BUILDROOT)/extlib/$(ARCH)
NA_EXTLIBDIR?=$(BUILDROOT)/extlib/noarch
else
EXTLIBDIR?=$(TRDIR)/extlib
NA_EXTLIBDIR?=$(TRDIR)/extlib
endif
NDEXTLIBDIR:=$(EXTLIBDIR).nodist
NDNA_EXTLIBDIR:=$(NA_EXTLIBDIR).nodist
EXTLIBDIR_READONLY?=1

ifeq ($(ISWINDOWS),true)
	LNDIR:=cp -r
	LNFILE:=cp
else
	LNDIR:=ln -sf
	LNFILE:=ln -sf
endif

# tell the bootstrap makefile to not define its own default download rule.
ABS_DEPDOWNLOAD_RULE_OVERLOADED:=1
# download files from repository
.PRECIOUS: $(ABS_CACHE)/%
.PRECIOUS: $(ABS_CACHE)/noarch/%
.PRECIOUS: $(ABS_CACHE)/noarch/%.tar.gz
.PRECIOUS: $(ABS_CACHE)/noarch/%.jar
.PRECIOUS: $(ABSWS_EXTLIBDIR)/%/import.mk $(ABSWS_NDEXTLIBDIR)/%/import.mk $(ABSWS_NA_EXTLIBDIR)/%/import.mk $(ABSWS_NDNA_EXTLIBDIR)/%/import.mk

# Download an archive from an URL list
# Each URL from given list is tried successively according the list order.
# No longer tries anything once the file has been succesfully downloaded once.
# $1: Name of file to download
# $2: URL list
# $3: Destination file path
define downloadFromURLs
@$(ABS_PRINT_info) "Fetching $1..."; \
	for repo in $2 ; do \
	$(ABS_PRINT_debug) "Fetching $1 from $$repo" ; \
	case $$repo in \
		file://*) srcfile=`echo "$$repo" | cut -f 2 -d ':'`;\
			test -f $$srcfile && ln -sf $$srcfile $3 ; \
			test -r $3 && $(ABS_PRINT_info) "$1 got from $$repo" && exit 0 || true;; \
		scp:*) srcfile=`echo "$$repo" | cut -f 2,3 -d ':'`;\
			scp $(SCPFLAGS) $$srcfile $3.tmp && mv $3.tmp $3 && $(ABS_PRINT_info) "$1 got from $$repo" && exit 0;;\
		*) wget -q $(WGETFLAGS) $$repo -O $3.tmp && mv $3.tmp $3 && touch $3 && $(ABS_PRINT_info) "$1 got from $$repo" && exit 0 || \
			rm -rf $3 ;; \
	esac \
done ; \
for repo in $2; do $(ABS_PRINT_warning) "$1 not available from $$repo"; done; \
$(ABS_PRINT_error) "Can't fetch $1." ; rm -rf $3 ; exit 1
endef

# Download an archive from repositories
# !!! Deprecated, downloadFromURLs shall be used.
# $1: File to download
# $2: Repositories list
# $3: Dest file
define downloadFromRepos
	$(ABS_PRINT_warning) "Macro downloadFromRepos is deprecated. ABS extension or project configuration should be updated to new ABS standards."
$(call downloadFromURLs,$1,$(patsubst %,%/$1,$2),$3)
endef

ifeq ($(findstring %,$(ABS_REPO)),)
ABS_REPO_PATTERN:=$(patsubst %,%/$(ARCH)/%,$(ABS_REPO))
ABS_REPO_NA_PATTERN:=$(patsubst %,%/noarch/%,$(ABS_REPO))
else
$(eval ABS_REPO_PATTERN:=$(ABS_REPO))
$(eval ABS_REPO_NA_PATTERN:=$(subst $$(ARCH),noarch,$(ABS_REPO)))
endif

# macro to get repos for a library
# Args:
#   - 1: pattern abs repo
#	- 2: name of the library archive (ex: libtest-0.0.1.NotALinux.tar.gz)
define getReposToUse
$(patsubst %,$1,$2) \
$(patsubst %,$1,$(call getLibNameFromArchiveName,$2,$(ALLUSELIB))/$2)
endef

# macro to get the list of repositories where to find dependencies
# Looking for $(ABS_REPO)/noarch/ and $(ABS_REPO)/noarch/<dependency name>/
# Args:
#   - 1: List of patterns abs repo
#	- 2: name of the library archive (ex: libtest-0.0.1.NotALinux.tar.gz)
define getReposToUseForNoArch
$(foreach pat,$(1),$(call getReposToUse,$(pat),$(2)))
endef
# macro to get the list of repositories where to find dependencies
# Looking for $(ABS_REPO)/$(ARCH)/ and $(ABS_REPO)/$(ARCH)/<dependency name>/
#             $(ABS_REPO)/noarch/ and $(ABS_REPO)/noarch/<dependency name>/
# Args:
#   - 1: List of patterns abs repo
#	- 2: name of the library archive (ex: libtest-0.0.1.NotALinux.tar.gz)
define getReposToUseForArch
$(foreach pat,$(1),$(call getReposToUse,$(pat),$(2))\
	$(subst $(ARCH),noarch,$(call getReposToUse,$(pat),$(2))))
endef

$(ABS_CACHE)/noarch/%:
	@mkdir -p $(@D)
	$(call downloadFromURLs,$*,$(call getReposToUseForNoArch,$(ABS_REPO_NA_PATTERN),$(@F)),$@)

$(ABS_CACHE)/%:
	@mkdir -p $(@D)
	$(call downloadFromURLs,$*,$(call getReposToUseForArch,$(ABS_REPO_PATTERN),$(@F)),$@)

# extract import.mk at the end to be sure the extraction is complete.
define unpackArchive
	@$(ABS_PRINT_info) "Unpacking library : $*"
	@$(ABS_PRINT_debug) "$<"
	@if [ -d $(@D) ]; then chmod -R u+w $(@D) && rm -rf $(@D); fi
	@mkdir -p $(@D)
	@tar --exclude=$*/import.mk -xmzf $< -C $(1)
	@tar -xmzf $< -C $(1) $*/import.mk
	@if [ $(EXTLIBDIR_READONLY) -eq 1 ]; then chmod -R a-w $(@D); fi
	@touch $@
endef

# unpack arch specific external lib
$(ABSWS_EXTLIBDIR)/%/import.mk: $(ABS_CACHE)/$(ARCH)/%.$(ARCH).tar.gz
	$(call unpackArchive,$(ABSWS_EXTLIBDIR))

# unpack external lib that should not be forwarded to dist package
$(ABSWS_NDEXTLIBDIR)/%/import.mk: $(ABS_CACHE)/$(ARCH)/%.$(ARCH).tar.gz
	$(call unpackArchive,$(ABSWS_NDEXTLIBDIR))

# unpack no arch external lib
$(ABSWS_NA_EXTLIBDIR)/%/import.mk: $(ABS_CACHE)/noarch/%.tar.gz
	$(call unpackArchive,$(ABSWS_NA_EXTLIBDIR))

# unpack no arch external lib that should not be forwarded to dist package
$(ABSWS_NDNA_EXTLIBDIR)/%/import.mk: $(ABS_CACHE)/noarch/%.tar.gz
	$(call unpackArchive,$(ABSWS_NDNA_EXTLIBDIR))


define extlib_linkLibrary
	@mkdir -p `dirname $(@D)`
	@mkdir -p $(TRDIR)
	@test -d $(@D) && rm $(@D) || true
	@$(LNDIR) $(<D) $(@D)
	@function createSymLinks() { \
		basedir=$$(readlink -f $$1) ;\
		subdir=$$2 ;\
		root=$$(readlink -f $$3) ;\
		[ -z "$${basedir}" ] && return ;\
		[ ! -d "$${basedir}/$${subdir}" ] && return ;\
		n=$$(echo "$${basedir}/$${subdir}" | wc -c) ;\
		subdirs=$$(find $${basedir}/$${subdir} -type d -not -path "*/doc/*" | sort | uniq) ;\
		for s in $${subdirs}; do \
			sd=$${s:$${n}} ;\
			[ ! -z "$${sd}" ] && mkdir -p $${root}/$${subdir}/$${sd} ;\
		done ;\
		files=$$(find $${basedir}/$${subdir} -type f -not -path "*/doc/*") ;\
		for f in $${files}; do \
			df=$$(dirname $$f) ;\
			d=$${df:$${n}} ;\
			[ -z "$$d" ] && d='.' ;\
			dest_dir=$${root}/$${subdir}/$${d};\
			mkdir -p $${dest_dir};\
			( cd $${dest_dir} ; ln -sf $$f ) ;\
		done ;\
	} ;\
	if [[ ! "$(TRDIR)" == *"/dist/flatten/"* ]]; then \
		$(ABS_PRINT_debug) "Creating symlinks for $$(basename $(@D)) dependency to $(TRDIR) ..." ;\
		for extd in etc share; do createSymLinks $(<D) $$extd $(TRDIR); done ;\
	fi
endef

# unpack arch specific external lib
$(EXTLIBDIR)/%/import.mk: $(ABSWS_EXTLIBDIR)/%/import.mk
	$(call extlib_linkLibrary)

# unpack external lib that should not be forwarded to dist package
$(NDEXTLIBDIR)/%/import.mk: $(ABSWS_NDEXTLIBDIR)/%/import.mk
	$(call extlib_linkLibrary)

# unpack no arch external lib
$(NA_EXTLIBDIR)/%/import.mk: $(ABSWS_NA_EXTLIBDIR)/%/import.mk
	$(call extlib_linkLibrary)

# unpack no arch external lib that should not be forwarded to dist package
$(NDNA_EXTLIBDIR)/%/import.mk: $(ABSWS_NDNA_EXTLIBDIR)/%/import.mk
	$(call extlib_linkLibrary)

# same for java libraries
$(NA_EXTLIBDIR)/%.jar: $(ABS_CACHE)/noarch/%.jar
	@mkdir -p $(@D)
	@$(LNFILE) -sf $< $@

$(NDNA_EXTLIBDIR)/%.jar: $(ABS_CACHE)/noarch/%.jar
	@mkdir -p $(@D)
	@$(LNFILE) $< $@

# --------------------------------------------------------------------
# general purpose noarch file sets
# for now activated only for doc modules since bad side effects have
# been encoutered on some projects (conflicting with smart responder
# models code generation).
$(ABSWS_NA_EXTLIBDIR)/%/.dir: $(ABS_CACHE)/noarch/%.tar.gz
	@$(ABS_PRINT_info) "Unpacking data file set : $*"
	@tar -xzf $< -C $(ABSWS_NA_EXTLIBDIR) && touch $@

$(ABSWS_NDNA_EXTLIBDIR)/%/.dir: $(ABS_CACHE)/noarch/%.tar.gz
	@$(ABS_PRINT_info) "Unpacking data file set : $*"
	@tar -xzf $< -C $(ABSWS_NDNA_EXTLIBDIR) && touch $@

$(NA_EXTLIBDIR)/%/.dir: $(ABSWS_NA_EXTLIBDIR)/%/.dir
	$(call extlib_linkLibrary)

$(NDNA_EXTLIBDIR)/%/.dir: $(ABSWS_NDNA_EXTLIBDIR)/%/.dir
	$(call extlib_linkLibrary)

ifneq ($(BUILDCHAIN),)
USELIB+=runtime-$(BUILDCHAIN)
endif

EXTLIBS_ALL_USELIB=$(USELIB)
EXTLIBS_ALL_NAUSELIB=$(NA_USELIB)
EXTLIBS_ALL_NDUSELIB=$(NDUSELIB)
EXTLIBS_ALL_NDNAUSELIB=$(NDNA_USELIB)

ALLUSELIB:=$(USELIB) $(NDUSELIB)
DEV_USELIB=$(filter-out $(DEV_USELIB_IGNORE),$(filter %d,$(ALLUSELIB)))

# macro to include lib
# $1 lib dependency name (name-version)
# $2 extlib directory path
# $3 variable to use to store libs
define extlib_import_include
$(eval $3+=$1)
$(patsubst %,$2/%/import.mk,$(subst |,-,$1))
endef

# macro to include lib
# $1 lib dependancy name (name-version)
# $2 lib parent name
# $3 extlib directory path
# $4 variable to use to store libs
define extlib_import4
$(eval ALLUSELIB+=$1)
$(if $(call isLibInList,$1,$($4) $(EXTLIBS_ALL_USELIB)),\
$(call abs_debug,$1 already imported. Ignoring new dependency from $2 to $1),\
$(call extlib_import_include,$1,$3,$4))
endef

define extlib_import_warn_imported
$(call abs_warning,$1 not imported from $2. Already imported another version: $(call getLibWithLibName,$(call getLibNameFromVersioned,$1),$(ALLUSELIB)))
$(eval NOTHING:=$(shell $(call writeToBuildLogs,$1 not imported because different version: $(call getLibWithLibName,$(call getLibNameFromVersioned,$1),$(ALLUSELIB)))))
$(eval DEPENDENCIES_ERROR=true)
$(eval ADDEDDEPLIST:=$(ADDEDDEPLIST)[color="red"] "$1"[color="red"])
endef

# macro to include lib
# $1 lib dependency name (name-version)
# $2 lib parent name
# $3 extlib directory path
# $4 variable to use to store libs
define extlib_import3
$(eval ADDEDDEPLIST:=$(ADDEDDEPLIST) "$2"->"$1")
$(if $(call isLibInListByName,$1,$(ALLUSELIB)),\
$(if $(call isLibInList,$1,$(ALLUSELIB)),\
$(call extlib_import4,$1,$2,$3,$4),\
$(call extlib_import_warn_imported,$1,$2)),\
$(call extlib_import4,$1,$2,$3,$4))
endef

# macro to include lib
# $1 lib dependency name
# $2 lib version
# $3 libs to include
# $4 extlib directory path
# $5 variable to use to store libs
define extlib_import2
$(foreach lib,$3,$(call extlib_import3,$(lib),$1-$2,$4,$5))
$(eval _app_$1_dir:=$4/$1-$2)
$(eval _app_$1_depends+=$(foreach lib,$3,$(call getLibNameFromVersioned,$(lib))))
$(eval ALL_LIBS_LOADED+=$1)
endef

# macro to include lib
# The return of the macro is the list of external libs to include (the import.mk paths).
# $1 lib dependency name
# $2 lib version
# $3 libs to include
# $4 variable to use to store libs
define extlib_import
$(if $(call isLibInList,$1-$2,$(EXTLIBS_ALL_USELIB)),$(call extlib_import2,$1,$2,$3,$(EXTLIBDIR),EXTLIBS_ALL_USELIB))
$(if $(call isLibInList,$1-$2,$(EXTLIBS_ALL_NAUSELIB)),$(call extlib_import2,$1,$2,$3,$(NA_EXTLIBDIR),EXTLIBS_ALL_NAUSELIB))
$(if $(call isLibInList,$1-$2,$(EXTLIBS_ALL_NDUSELIB)),$(call extlib_import2,$1,$2,$3,$(NDEXTLIBDIR),EXTLIBS_ALL_NDUSELIB))
$(if $(call isLibInList,$1-$2,$(EXTLIBS_ALL_NDNAUSELIB)),$(call extlib_import2,$1,$2,$3,$(NDNA_EXTLIBDIR),EXTLIBS_ALL_NDNAUSELIB))
$(eval ABS_INCLUDE_MODS+=$1)
endef

define extlib_import_template
include $$(strip $$(call extlib_import,$1,$2,$3))

$$(NA_EXTLIBDIR)/%.jar: $$(EXTLIBDIR)/$1-$2/lib/%.jar
	@$$(ABS_PRINT_info) "Importing jar lib $$(@F)..."
	@mkdir -p $$(@D)
	@$$(LNFILE) $$< $$@
endef
# list of import makefile from external libraries declared in module
# configuration only if not requesting clean or cleanabs target. In this case,
# we don't care importing the dependencies.
ifeq ($(filter clean% purgeabs docker% tag,$(MAKECMDGOALS)),)

EXTLIBMAKES=$(patsubst %,$(EXTLIBDIR)/%/import.mk,$(subst |,-,$(USELIB))) \
	$(patsubst %,$(NDEXTLIBDIR)/%/import.mk,$(subst |,-,$(NDUSELIB))) \
	$(patsubst %,$(NDNA_EXTLIBDIR)/%/import.mk,$(subst |,-,$(NDNA_USELIB))) \
	$(patsubst %,$(NA_EXTLIBDIR)/%/import.mk,$(subst |,-,$(NA_USELIB)))

ifeq ($(filter getdeps,$(MAKECMDGOALS)),)
# these wraps permit to have files that are not generated by getdeps
# => to not reinclude already imported files and therefore have partial dependencies.
EXTLIBMAKE_DEFAULT_LIBS=$(sort $(USELIB) $(NDUSELIB) $(NDNA_USELIB) $(NA_USELIB))
EXTLIBMAKE_FULL_IMPORTED:=$(patsubst %,$(EXTLIBS_GENE_FILES_DIR)/.%_fullyImported,$(subst |,-,$(EXTLIBMAKE_DEFAULT_LIBS)))

# use allinclude.mk to be able to get all dependencies first.
$(ALL_INCLUDED_FILE): $(ALL_PROJ_MODDEPS_MK) $(PRJROOT)/app.cfg 
	@mkdir -p $(@D)
	@$(ABS_PRINT_info) "Getting all dependencies"
	@+make --no-print-directory getdeps PRJROOT="$(PRJROOT)" TRDIR="$(TRDIR)" PRJOBJDIR="$(PRJOBJDIR)"
	@$(ABS_PRINT_info) "Getting all dependencies done"
	@touch $@

$(EXTLIBS_GENE_FILES_DIR)/.%_fullyImported: $(ALL_INCLUDED_FILE)
	@$(ABS_PRINT_debug) "Creation of $@"
	@test -d $(@D) && chmod +w $(@D) || mkdir -p $(@D)
	@echo "include $(filter %/$*/import.mk,$(EXTLIBMAKES))" > $@

include $(EXTLIBMAKE_FULL_IMPORTED)
# external libraries are expected before starting compilation.
$(OBJS): $(EXTLIBMAKE_FULL_IMPORTED)

else
include $(EXTLIBMAKES)
# external libraries are expected before starting compilation.
$(OBJS): $(EXTLIBMAKES)

endif


# --------------------------------
# Print warning or fail according strict checking mode when
# USELIB check has detected inconsistencies
# --------------------------------
ifneq ($(MAKECMDGOALS),checkdep%)
ifeq ($(DEPENDENCIES_ERROR),true)
ifneq ($(ABS_STRICT_DEP_CHECK),)
$(call abs_error,================================================================)
$(call abs_error,                     ERROR)
$(call abs_error,Same lib used with different version. Check USELIB definitions.)
$(call abs_error,USELIB is: $(USELIB))
$(call abs_error,Launch 'make checkdep' to see dependency graph.)
$(call abs_error,================================================================)
ABS_FATAL:=true
else
$(call abs_warning,================================================================)
$(call abs_warning,                           WARNING)
$(call abs_warning,Same lib used with different version. Check USELIB definitions.)
$(call abs_warning,USELIB is: $(USELIB))
$(call abs_warning,Launch 'make checkdep' to see dependency graph.)
$(call abs_warning,================================================================)
endif # ifneq ($(ABS_STRICT_DEP_CHECK),)
endif # ifeq ($(DEPENDENCIES_ERROR),true)

ifneq ($(DEV_USELIB),)
ifneq ($(ABS_STRICT_DEP_CHECK),)
$(call abs_error,================================================================)
$(call abs_error,                     ERROR)
$(call abs_error,Dependencies include non tagged libraries.)
$(call abs_error,$(sort $(DEV_USELIB)))
$(call abs_error,Launch 'make checkdep' to see the full dependency graph.)
$(call abs_error,================================================================)
ABS_FATAL:=true
else
$(call abs_warning,================================================================)
$(call abs_warning,                           WARNING)
$(call abs_warning,Dependencies include non tagged libraries.)
$(call abs_warning,$(sort $(DEV_USELIB)))
$(call abs_warning,Launch 'make checkdep' to see the full dependency graph.)
$(call abs_warning,================================================================)
endif # ifneq ($(ABS_STRICT_DEP_CHECK),)
NOTHING:=$(shell $(call writeToBuildLogs,Non tagged dependency: $(sort $(DEV_USELIB))))
endif # ifneq ($(DEV_USELIB),)
endif # ifneq ($(MAKECMDGOALS),checkdep%)

## Targets:
##  - checkdep: show currently defined dependencies (full graph including
##    dependencies of dependencies).
##  - checkdeptest: show currently defined dependencies including test (full graph including
##    dependencies of dependencies).
ifneq ($(USELIB),)
define generateCheckDep
	@$(ABS_PRINT_info) "Generating project dependency graph."
	@printf 'digraph deps {\ngraph [rankdir="LR",ranksep=1];\nnode [width=2, shape=box, style="rounded"];\n' > $@
	@printf ' $(foreach dep,$(subst |,-,$1),"$(APPNAME)-$(VERSION)"->"$(dep)";\n)' | sed -e 's/d";$$/d"\[color="orange"\];/g'>> $@
	@printf ' $(foreach dep,$(subst |,-,$(ADDEDDEPLIST)),$(dep);\n)' | sort -u | sed -e 's/d";$$/d"\[color="orange"\];/g'>> $@
	@echo "}" >> $@
	@dot -Tpng $@ > $@.png
endef

define showCheckDep
	@$(ABS_PRINT_info) "Launching image viewer to display the generated dependency graph $<.png."
	@$(ABS_PRINT_info) "Close image viewer to continue or hit Ctrl-C to stop here."
	@xdot $< 2>/dev/null || eog $<.png 2>/dev/null || xdg-open $<.png 2>/dev/null || $(ABS_PRINT_error) "No image viewer found (expected one of: xdot, eog, xdg-open)"
endef

$(BUILDROOT)/$(APPNAME)_deps.dot: $(PRJROOT)/app.cfg
	@$(call generateCheckDep,$(USELIB) $(TUSELIB))
	
$(BUILDROOT)/$(APPNAME)_testdeps.dot: $(PRJROOT)/app.cfg
	@$(call generateCheckDep,$(USELIB))

checkdep: $(BUILDROOT)/$(APPNAME)_deps.dot
	@$(call showCheckDep)
	

checkdeptest: $(BUILDROOT)/$(APPNAME)_testdeps.dot
	@$(call showCheckDep)

else #ifneq ($(USELIB),)
checkdep:
	@$(ABS_PRINT_info) "No dependencies set in USELIB project parameter."

checkdeptest:
	@$(ABS_PRINT_info) "No dependencies set in USELIB project parameter."
endif #ifneq ($(USELIB),)
endif # ifeq ($(filter cleandist clean cleanabs purgeabs,$(MAKECMDGOALS)),)

getdep: $(EXTLIBMAKES)
	@:

##  - getdeps: download dependencies
getdeps: $(EXTLIBMAKES)
	@:

##  - getdepstest: download dependencies (test dependencies too)
getdepstest: getdeps
	@:
