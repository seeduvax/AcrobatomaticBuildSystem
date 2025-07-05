## 
## ------------------------------------------------------------------------
## Dependencies management
## ------------------------------------------------------------------------

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
# macro to get the lib version from <libname>-<version> or <libname>|<version>
# 1: the name of lib with version.
define getLibVersionFromVersioned
$(if $(findstring |,$1),$(word 2,$(subst |, ,$1)),$(subst $(word 1,$(subst -, ,$1))-,,$1))
endef

# macro to get the list from a list using its name.
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

# Get the name of the library from LINKLIB variable
# 1: link libs
# return the list of the libraries if possible.
define getLibrariesNameFromLinklib
$(foreach lib,$1,$(if $(_module_$(lib)_dir)$(_app_$(lib)_dir),$(lib),$(if $(_app_lib$(lib)_dir),lib$(lib))))
endef

# resolve all dependencies by transitivity from dependencies (private macro)
# 1: module/apps name
# 2: name of the variable for the list of already added dependencies (to avoid loop)
# return the list of the dependencies.
define _getDependenciesByTransitivity2
$(filter-out $($2),$1) \
$(foreach element,$(filter-out $($2),$1),$(eval $2+=$(element))$(call _getDependenciesByTransitivity2,$(_module_$(element)_depends) $(_app_$(element)_depends),$2))
endef

# resolve all dependencies by transitivity from dependencies (private macro)
# 1: module/apps name
# 2: name of the variable for the list of already added dependencies (to avoid loop)
# return the list of the dependencies.
define _getDependenciesByTransitivity1
$(eval $2=)$(sort $(call _getDependenciesByTransitivity2,$1,$2))
endef

# resolve all dependencies by transitivity from dependencies
# 1: module/apps name
# return the list of the dependencies.
define getDependenciesByTransitivity
$(call _getDependenciesByTransitivity1,$1,$(call generateTmpVariable,_depvar_))
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
EXTLIBDIR_READONLY?=true

UNPACK_ARGS=
ifeq ($(ISWINDOWS),true)
	LNDIR:=cp -r
	LNFILE:=cp
	RMLINK:=rm -rf
else
	LNDIR:=ln -sf
	LNFILE:=ln -sf
	RMLINK:=rm
endif

# tell the bootstrap makefile to not define its own default download rule.
ABS_DEPDOWNLOAD_RULE_OVERLOADED:=1
# download files from repository
.PRECIOUS: $(ABS_CACHE)/%
.PRECIOUS: $(ABS_CACHE)/noarch/%
.PRECIOUS: $(ABS_CACHE)/noarch/%.tar.gz
.PRECIOUS: $(ABS_CACHE)/noarch/%.jar
.PRECIOUS: $(ABSWS_EXTLIBDIR)/%/import.mk $(ABSWS_NDEXTLIBDIR)/%/import.mk $(ABSWS_NA_EXTLIBDIR)/%/import.mk $(ABSWS_NDNA_EXTLIBDIR)/%/import.mk

OPEN_BRACE:={
ABS_REPO_TEMPLATE=$(foreach entry, $(ABS_REPO),$(if $(findstring $(OPEN_BRACE),$(entry)),$(entry),$(entry)/{arch}/{name}-{version}.{arch}.{ext} $(entry)/{arch}/{name}/{name}-{version}.{arch}.{ext} $(entry)/{arch}/{name}-{version}.{ext}))

# fetch package with wget (any URL kind that wget can handle)
# Caution: empty line at end of macro def is required for proper commands
# separation when expansed to the using target full script.
# $1 URL to download from
# $2 destination file path
define downloadFromUrlTo
	@test -f $2 || ( $(ABS_PRINT_debug) "Downloading $1..." ; wget -q $(WGETFLAGS) $1 -O $2 || rm -f $2 )

endef

# fetch package by linking to local file
# Caution: empty line at end of macro def is required for proper commands
# separation when expansed to the using target full script.
# $1 local file URL
# $2 destination file path
define linkFromFileUrlTo
	@test -f $2 || ( $(ABS_PRINT_debug) "Linking $1..." ; ln -sf $(patsubst file://%,%,$1) $2 ; test -r $2 || rm -f $2 )

endef

# fetch package with scp
# Caution: empty line at end of macro def is required for proper commands
# separation when expansed to the using target full script.
# $1 source URL
# $2 destination file path
define scpFromFileUrlTo
	@test -f $2 || ( $(ABS_PRINT_debug) "Downloading $1..." ; scp $(SCPFLAGS) $(patsubst scp:%,%,$1) $2 || : )

endef

# build list of commands to fetch package
# $1 target file
# $2 list of URL to try to get the package.
define downloadFromURLs
$(foreach entry,$2,$(if $(filter file://%,$(entry),),$(call linkFromFileUrlTo,$(entry),$1))$(if $(filter scp:%,$(entry),),$(call scpFromFileUrlTo,$(entry),$1))$(if $(filter-out file://% scp:%,$(entry)),$(call downloadFromUrlTo,$(entry),$1)))

@test -f $1 || ($(ABS_PRINT_error) "Cannot get library $1"; $(foreach entry,$2,$(ABS_PRINT_warning) "   tried $(entry)";) )
endef

# Get list of concrete URL for each ABS repo pattern and package attributes
# $1 package name
# $2 package version
# $3 architecture name
# $4 file extension
define SubstituteRepoTemplate
$(subst {name},$1,$(subst {version},$2,$(subst {arch},$3,$(subst {ext},$4,$(ABS_REPO_TEMPLATE)))))
endef

# Get the path to the external directory for a specified library
# $1: root path of extlib dir ($(EXTLIBDIR), ...)
# $2: library with version (ex: cppunit|1.14.0)
define GetExtLibDir
$1/$(call getLibNameFromVersioned,$2)/$(call getLibVersionFromVersioned,$2)
endef

# Get the path to the external directory for a specified library
# $1: root path of extlib dir ($(EXTLIBDIR), ...)
# $2: library with version (ex: cppunit|1.14.0)
# $3: extension
define GetExtLibFile
$(call GetExtLibDir,$1,$2)/pck.$3
endef


# Get URL list related to a package
# $1 package file name. expected format is <name>/<version>/pck.<ext>
define GetDownloadURLs
$(call SubstituteRepoTemplate,$(word 1,$(subst /, ,$1)),$(word 2,$(subst /, ,$1)),$(ARCH),$(subst pck.,,$(word 3,$(subst /, ,$1)))) \
$(if $(filter $(ARCH),$(KERNARCH)),,$(call SubstituteRepoTemplate,$(word 1,$(subst /, ,$1)),$(word 2,$(subst /, ,$1)),$(KERNARCH),$(subst pck.,,$(word 3,$(subst /, ,$1))))) \
$(call SubstituteRepoTemplate,$(word 1,$(subst /, ,$1)),$(word 2,$(subst /, ,$1)),noarch,$(subst pck.,,$(word 3,$(subst /, ,$1))))
endef

define GetNoarchDownloadURLs
$(call SubstituteRepoTemplate,$(word 1,$(subst /, ,$1)),$(word 2,$(subst /, ,$1)),noarch,$(subst pck.,,$(word 3,$(subst /, ,$1))))
endef

# Get URL list related to a raw package package file name
# $1 package file name where package name has no structure.
define GetRawPckNameDownloadURLs
$(foreach entry,$(ABS_REPO_TEMPLATE),$(if $(findstring {file},$(entry)),$(subst {file},$1,$(entry))))
endef

$(ABS_CACHE)/noarch/%:
	@mkdir -p $(@D)
	@$(ABS_PRINT_info) "Fetching NA $*..."
	$(call downloadFromURLs,$@.tmp,$(call GetNoarchDownloadURLs,$(subst $(ABS_CACHE)/noarch/,,$@)))
	@mv $@.tmp $@
	@test -f $@
	$(eval _local_target_spec:=$(subst /, ,$(patsubst $(ABS_CACHE)/noarch/%,%,$@)))
	$(if $(filter %.jar,$(@F)),mv $@ $(ABS_CACHE)/noarch/$(word 1,$(_local_target_spec))-$(word 2,$(_local_target_spec)).jar;ln -s $(ABS_CACHE)/noarch/$(word 1,$(_local_target_spec))-$(word 2,$(_local_target_spec)).jar $@,)


$(ABS_CACHE)/%:
	@mkdir -p $(@D)
	@$(ABS_PRINT_info) "Fetching $*..."
	$(call downloadFromURLs,$@.tmp,$(call GetDownloadURLs,$(subst $(ABS_CACHE)/$(ARCH)/,,$@)))
	@mv $@.tmp $@
	@test -f $@

# extract import.mk at the end to be sure the extraction is complete.
define unpackArchive
	@$(ABS_PRINT_info) "Unpacking library : $*"
	@$(ABS_PRINT_debug) "$<"
	@$(if $(wildcard $(@D)),chmod -R u+w $(@D) && rm -rf $(@D))
	@mkdir -p $(@D)
	@tar -xmzf $< -C $(@D) --strip-components=1
	@$(if $(filter 1 true,$(EXTLIBDIR_READONLY)),chmod -R a-w $(@D))
	@touch $@
endef

# unpack arch specific external lib
$(ABSWS_EXTLIBDIR)/%/import.mk: $(ABS_CACHE)/$(ARCH)/%/pck.tar.gz
	$(call unpackArchive,$(ABSWS_EXTLIBDIR))

# unpack external lib that should not be forwarded to dist package
$(ABSWS_NDEXTLIBDIR)/%/import.mk: $(ABS_CACHE)/$(ARCH)/%/pck.tar.gz
	$(call unpackArchive,$(ABSWS_NDEXTLIBDIR))

# unpack no arch external lib
$(ABSWS_NA_EXTLIBDIR)/%/import.mk: $(ABS_CACHE)/noarch/%/pck.tar.gz
	$(call unpackArchive,$(ABSWS_NA_EXTLIBDIR))

# unpack no arch external lib that should not be forwarded to dist package
$(ABSWS_NDNA_EXTLIBDIR)/%/import.mk: $(ABS_CACHE)/noarch/%/pck.tar.gz
	$(call unpackArchive,$(ABSWS_NDNA_EXTLIBDIR))


define extlib_linkLibrary
	@mkdir -p `dirname $(@D)`
	@mkdir -p $(TRDIR)
	@$(if $(wildcard $(@D)),$(RMLINK) $(@D))
	@$(LNDIR) $(<D) $(@D)
	@$(if $(filter $(TR_DIST_DIR),$(TRDIR)),,function createSymLinks() { \
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
	$(ABS_PRINT_debug) "Creating symlinks for $$(basename $(@D)) dependency to $(TRDIR) ..." ;\
	for extd in etc share; do createSymLinks $(<D) $$extd $(TRDIR); done ;)
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
# caution: current way of linking jars is not accurate, TODO find a way to
#          retrieve the file name it has on the repository where it is found.
# $(NA_EXTLIBDIR)/%.jar: $(ABS_CACHE)/noarch/%.jar
# 	$(eval _local_target_spec:=$(subst /, ,$(patsubst $(ABS_CACHE)/noarch/%.jar,%,$<)))
# 	@mkdir -p $(@D)
# 	@cp $< $(NA_EXTLIBDIR)/$(word 1,$(_local_target_spec))-$(word 2,$(_local_target_spec)).jar
# 	@date > $@
# 
# $(NDNA_EXTLIBDIR)/%.jar: $(ABS_CACHE)/noarch/%.jar
# 	$(eval _local_target_spec:=$(subst /, ,$(patsubst $(ABS_CACHE)/noarch/%.jar,%,$<)))
# 	@mkdir -p $(@D)
# 	@cp $< $(NDNA_EXTLIBDIR)/$(word 1,$(_local_target_spec))-$(word 2,$(_local_target_spec)).jar
# 	@date > $@

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
USELIB+=runtime|$(BUILDCHAIN)
endif

# USELIB / NDUSELIB from modules. (needed for dist)
# permit to load external dependencies during app level initialization.
MODS_USELIBS=$(sort $(_modules_$(APPNAME)_uselib))
MODS_NDUSELIBS=$(sort $(_modules_$(APPNAME)_nduselib))

EXTLIBS_ALL_USELIB=$(sort $(USELIB) $(MODS_USELIBS))
EXTLIBS_ALL_NDUSELIB=$(sort $(NDUSELIB) $(MODS_NDUSELIBS))
EXTLIBS_ALL_NAUSELIB=$(NA_USELIB)
EXTLIBS_ALL_NDNAUSELIB=$(NDNA_USELIB)

ALLUSELIB=$(sort $(USELIB) $(NDUSELIB) $(MODS_USELIBS) $(MODS_NDUSELIBS))
DEV_USELIB=$(filter-out $(DEV_USELIB_IGNORE),$(filter %d,$(ALLUSELIB)))

# macro to include lib
# $1 lib dependency name (name-version)
# $2 extlib directory path
# $3 variable to use to store libs
define extlib_import_include
$(eval $3+=$1)
$(call GetExtLibDir,$2,$1)/import.mk
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
$(eval _app_$1_dir:=$4/$1/$2)
$(eval _app_$1_depends+=$(foreach lib,$3,$(call getLibNameFromVersioned,$(lib))))
$(eval ALL_LIBS_LOADED+=$1)
endef

# macro to include lib
# The return of the macro is the list of external libs to include (the import.mk paths).
# $1 lib dependency name
# $2 lib version
# $3 libs to include
# return the list of import.mk to include
define extlib_import
$(if $(call isLibInList,$1-$2,$(EXTLIBS_ALL_USELIB)),$(call extlib_import2,$1,$2,$3,$(EXTLIBDIR),EXTLIBS_ALL_USELIB))
$(if $(call isLibInList,$1-$2,$(EXTLIBS_ALL_NAUSELIB)),$(call extlib_import2,$1,$2,$3,$(NA_EXTLIBDIR),EXTLIBS_ALL_NAUSELIB))
$(if $(call isLibInList,$1-$2,$(EXTLIBS_ALL_NDUSELIB)),$(call extlib_import2,$1,$2,$3,$(NDEXTLIBDIR),EXTLIBS_ALL_NDUSELIB))
$(if $(call isLibInList,$1-$2,$(EXTLIBS_ALL_NDNAUSELIB)),$(call extlib_import2,$1,$2,$3,$(NDNA_EXTLIBDIR),EXTLIBS_ALL_NDNAUSELIB))
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
EXTLIBMAKES= \
	$(foreach entry,$(sort $(USELIB) $(MODS_USELIBS)),$(call GetExtLibDir,$(EXTLIBDIR),$(entry))/import.mk) \
	$(foreach entry,$(sort $(NDUSELIB) $(MODS_NDUSELIBS)),$(call GetExtLibDir,$(NDEXTLIBDIR),$(entry))/import.mk) \
	$(foreach entry,$(sort $(NDNA_USELIB)),$(call GetExtLibDir,$(NDNA_EXTLIBDIR),$(entry))/import.mk) \
	$(foreach entry,$(sort $(NA_USELIB)),$(call GetExtLibDir,$(NA_EXTLIBDIR),$(entry))/import.mk)
	

DEFAULT_EXTLIBMAKES:=$(EXTLIBMAKES)

# The TUSELIB are libraries not needed for the main build but needed for the tests.
ifneq ($(INCTESTS),)
# add TUSELIB after to not objs depends on it
NDUSELIB+=$(TUSELIB)
endif

# Macro to launch the inclusion of externals libs.
# This macro only included not already included dependency.
ALREADY_INCLUDED=
define extlib_updates_deps
include $(filter-out $(ALREADY_INCLUDED),$(EXTLIBMAKES))
ALREADY_INCLUDED+=$(filter-out $(ALREADY_INCLUDED),$(EXTLIBMAKES))
endef

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
##  - checkmodsdep: show currently defined modules dependencies (full graph including
##    dependencies of dependencies of modules).
##  - checkdeptest: show currently defined dependencies including test (full graph including
##    dependencies of dependencies).
ifneq ($(USELIB),)
define generateCheckDep
	@$(ABS_PRINT_info) "Generating project dependency graph."
	@printf 'digraph deps {\ngraph [rankdir="LR",ranksep=1];\nnode [width=2, shape=box, style="rounded"];\n' > $@
	@printf ' $(foreach dep,$(subst |,-,$(sort $1)),"$(APPNAME)-$(VERSION)"->"$(dep)";\n)' | sed -e 's/d";$$/d"\[color="orange"\];/g'>> $@
	@printf ' $(foreach dep,$(subst |,-,$(ADDEDDEPLIST)),$(dep);\n)' | sort -u | sed -e 's/d";$$/d"\[color="orange"\];/g'>> $@
	@echo "}" >> $@
	@dot -Tpng $@ > $@.png
endef

define getModsDepsForGraph
$(if $(filter $1,$2),,$(foreach depend,$(_module_$1_depends),"$1"->"$(depend)";\n $(call getModsDepsForGraph,$(depend),$2 $1)))
endef
define generateCheckModDep
	@$(ABS_PRINT_info) "Generating modules dependency graph."
	@printf 'digraph deps {\ngraph [rankdir="LR",ranksep=1];\nnode [width=2, shape=box, style="rounded"];\n' > $@
	@printf ' $(sort $(foreach dep,$(subst |,-,$1),$(call getModsDepsForGraph,$(APPNAME)_$(dep))))' | sort -u>> $@
	@echo "}" >> $@
	@dot -Tpng $@ > $@.png
endef

define showCheckDep
	@$(ABS_PRINT_info) "Launching image viewer to display the generated dependency graph $<.png."
	@$(ABS_PRINT_info) "Close image viewer to continue or hit Ctrl-C to stop here."
	@xdot $< 2>/dev/null || eog $<.png 2>/dev/null || xdg-open $<.png 2>/dev/null || $(ABS_PRINT_error) "No image viewer found (expected one of: xdot, eog, xdg-open)"
endef

$(BUILDROOT)/$(APPNAME)_deps.dot: $(PRJROOT)/app.cfg
	@$(call generateCheckDep,$(USELIB))
	
$(BUILDROOT)/$(APPNAME)_testdeps.dot: $(PRJROOT)/app.cfg
	@$(call generateCheckDep,$(USELIB) $(NDUSELIB))

$(BUILDROOT)/$(APPNAME)_modsdeps.dot: $(PRJROOT)/app.cfg
	@$(call generateCheckModDep,$(MODULES))

checkdep: $(BUILDROOT)/$(APPNAME)_deps.dot
	@$(call showCheckDep)

checkmodsdep: $(BUILDROOT)/$(APPNAME)_modsdeps.dot
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
