## 
## ------------------------------------------------------------------------
## Dependencies management
## ------------------------------------------------------------------------
ALLINCLUDES_MK=$(PRJOBJDIR)/allInclude.mk

# replace the | by - in libs specifications.
USELIB_FOR_PATH=$(subst |,-,$(USELIB))

ifeq ($(filter clean% docker% tag,$(MAKECMDGOALS)),)
# do not process ext libs if target is clean or docker..
# the extlibs will be retrieved inside the container

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
TRANSUSELIB:=$(USELIB)
ALLUSELIB:=$(TRANSUSELIB) $(NDUSELIB)
DEV_USELIB=$(filter-out $(DEV_USELIB_IGNORE),$(filter %d,$(ALLUSELIB)))
# macro to include lib
# $1 lib dependancy name (name-version)
# $3 lib parent name
# $3 extlib directory path
# $4 variable to use to store libs
define includeExtLib
# the import.mk must not be imported if already imported in EXTLIB
ifeq ($$(call isLibInList,$1,$$($4) $$(TRANSUSELIB)),)
$$(eval $4+=$1)
include $$(patsubst %,$3/%/import.mk,$$(subst |,-,$1))
else
$$(call abs_debug,$1 already imported. Ignoring new dependency from $2 to $1)
endif

endef

# macro to include lib
# $1 lib dependency name (name-version)
# $2 lib parent name
# $3 extlib directory path
# $4 variable to use to store libs
define condIncludeExtLib
$$(eval ADDEDDEPLIST:=$$(ADDEDDEPLIST) "$2"->"$1")
ifeq ($$(call isLibInListByName,$1,$$(ALLUSELIB)),)
# the lib has not been imported yet
ALLUSELIB+=$1
$(call includeExtLib,$1,$2,$3,$4)
else
ifeq ($$(call isLibInList,$1,$$(ALLUSELIB)),)
$$(call abs_warning,$1 not imported from $2. Already imported another version: $$(call getLibWithLibName,$$(call getLibNameFromVersioned,$1),$$(ALLUSELIB)))
NOTHING:=$$(shell $$(call writeToBuildLogs,$1 not imported because different version: $$(call getLibWithLibName,$$(call getLibNameFromVersioned,$1),$$(ALLUSELIB))))
DEPENDENCIES_ERROR=true
$$(eval ADDEDDEPLIST:=$$(ADDEDDEPLIST)[color="red"] "$1"[color="red"])
else
# same version
$(call includeExtLib,$1,$2,$3,$4)
endif
endif

endef

# macro to be expansed at external lib inclusion.
# $1 lib name
# $2 lib version
# $3 lib's dependencies.
# Regex to get the name of module from lib can accept pattern like (projA-1.2.3_clang-13, projA-1.2.3, proj12A-2.63, ...)
define extlib_import_template
ifneq ($$(call isLibInList,$1-$2,$$(TRANSUSELIB)),)
$(foreach lib,$3,$(call condIncludeExtLib,$(lib),$1-$2,$(EXTLIBDIR),TRANSUSELIB))
_app_$1_dir:=$(EXTLIBDIR)/$1-$2
_app_$1_depends+=$(foreach lib,$3,$(call getLibNameFromVersioned,$(lib)))
ALL_LIBS_LOADED+=$1
else
ifneq ($$(call isLibInList,$1-$2,$$(NA_USELIB)),)
$(foreach lib,$3,$(call condIncludeExtLib,$(lib),$1-$2,$(NA_EXTLIBDIR),NA_USELIB))
_app_$1_dir:=$(NA_EXTLIBDIR)/$1-$2
_app_$1_depends+=$(foreach lib,$3,$(call getLibNameFromVersioned,$(lib)))
ALL_LIBS_LOADED+=$1
else
ifneq ($$(call isLibInList,$1-$2,$$(NDUSELIB)),)
$(foreach lib,$3,$(call condIncludeExtLib,$(lib),$1-$2,$(NDEXTLIBDIR),NDUSELIB))
_app_$1_dir:=$(NDEXTLIBDIR)/$1-$2
_app_$1_depends+=$(foreach lib,$3,$(call getLibNameFromVersioned,$(lib)))
ALL_LIBS_LOADED+=$1
else
ifneq ($$(call isLibInList,$1-$2,$$(NDNA_USELIB)),)
$(foreach lib,$3,$(call condIncludeExtLib,$(lib),$1-$2,$(NDNA_EXTLIBDIR),NDNA_USELIB))
_app_$1_dir:=$(NDNA_EXTLIBDIR)/$1-$2
_app_$1_depends+=$(foreach lib,$3,$(call getLibNameFromVersioned,$(lib)))
ALL_LIBS_LOADED+=$1
endif
endif
endif
endif

ABS_INCLUDE_MODS+=$1

$(NA_EXTLIBDIR)/%.jar: $(EXTLIBDIR)/$1-$2/lib/%.jar
	@$$(ABS_PRINT_info) "Importing jar lib $$(@F)..."
	@mkdir -p $$(@D)
	@$(LNFILE) $$< $$@

endef

# list of import makefile from external libraries declared in module
# configuration only if not requesting clean or cleanabs target. In this case,
# we don't care importing the dependencies.
ifeq ($(filter cleandist clean cleanabs purgeabs,$(MAKECMDGOALS)),)

EXTLIBMAKES=$(patsubst %,$(EXTLIBDIR)/%/import.mk,$(subst |,-,$(TRANSUSELIB))) \
	$(patsubst %,$(NDEXTLIBDIR)/%/import.mk,$(subst |,-,$(NDUSELIB))) \
	$(patsubst %,$(NDNA_EXTLIBDIR)/%/import.mk,$(subst |,-,$(NDNA_USELIB))) \
	$(patsubst %,$(NA_EXTLIBDIR)/%/import.mk,$(subst |,-,$(NA_USELIB)))

ifeq ($(filter getdeps,$(MAKECMDGOALS)),)
# use allinclude.mk to be able to get all dependencies first.
$(ALLINCLUDES_MK): $(PRJROOT)/app.cfg
	@mkdir -p $(@D)
	@$(ABS_PRINT_info) "Getting all dependencies"
	@+make --no-print-directory getdeps
	@$(ABS_PRINT_debug) "Creation of $@"
	@echo 'include $$(EXTLIBMAKES)' > $@.tmp
	@echo '$$(OBJS): $$(EXTLIBMAKES)' >> $@.tmp
	@mv $@.tmp $@

include $(ALLINCLUDES_MK)
else
include $(EXTLIBMAKES)
# external libraries are expected before starting compilation.
$(OBJS): $(EXTLIBMAKES)
endif
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
endif
endif

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
endif
NOTHING:=$(shell $(call writeToBuildLogs,Non tagged dependency: $(sort $(DEV_USELIB))))
endif
endif

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
endif

getdep: $(EXTLIBMAKES)
	@:

##  - getdeps: download dependencies
getdeps: $(EXTLIBMAKES)
	@:

##  - getdepstest: download dependencies (test dependencies too)
getdepstest: getdeps
	@:
