##
## ------------------------------------------------------------------------
## Dependencies management
## ------------------------------------------------------------------------

ifeq ($(filter clean% docker%,$(MAKECMDGOALS)),)
# do not process ext libs if target is clean or docker..
# the extlibs will be retrieved inside the container

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

ECLIPSE_PRJ=$(PRJROOT)/.project
DEPTOOL:=$(ABSROOT)/core/deptool.bash

# tell the bootstrap makefile to not define its own default download rule.
ABS_DEPDOWNLOAD_RULE_OVERLOADED:=1
# download files from repository
.PRECIOUS: $(ABS_CACHE)/%
.PRECIOUS: $(ABSWS_EXTLIBDIR)/%/import.mk $(ABSWS_NDEXTLIBDIR)/%/import.mk $(ABSWS_NA_EXTLIBDIR)/%/import.mk $(ABSWS_NDNA_EXTLIBDIR)/%/import.mk

# Download an archive from repositories
# $1: File to download
# $2: Repositories list
# $3: Dest file
#
define downloadFromRepos
@for repo in $2 ; do \
	$(ABS_PRINT_info) "Fetching $1 from $$repo" ; \
	case $$repo in \
		file://*) srcfile=`echo "$$repo" | cut -f 2 -d ':'`/$1 ;\
			test -f $$srcfile && ln -sf $$srcfile $3 ; \
			test -r $3 && exit 0 || \
			$(ABS_PRINT_warning) "$1 not available from $$repo";; \
		scp:*) srcfile=`echo "$$repo" | cut -f 2,3 -d ':'`/$1 ;\
			scp $(SCPFLAGS) $$srcfile $3 && exit 0;;\
		*) wget -q $(WGETFLAGS) $$repo/$1 -O $3 && exit 0 || \
			rm -rf $3 ; \
			 $(ABS_PRINT_warning) "$1 not available from $$repo";; \
	esac \
done ; $(ABS_PRINT_error) "Can't fetch $1." ; rm -rf $3 ; exit 1
endef


$(ABS_CACHE)/%:
	@mkdir -p $(@D)
	$(call downloadFromRepos,$*,$(ABS_REPO),$@)

define unpackArchive
	@$(ABS_PRINT_info) "Unpacking library : $(patsubst $(1)/%/import.mk,%,$@)"
	@$(ABS_PRINT_debug) "$^"
	@if [ -d $(@D)  ]; then chmod -R u+w $(@D) && rm -rf $(@D); fi
	@mkdir -p $(@D)
	@tar -xzf $^ -C $(1) && touch $@
	@if [ -f "$(ECLIPSE_PRJ)" ]; then chmod -R a-w $(@D); fi
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
	@test -d $(@D) && rm $(@D) || true
	@ln -s $(<D) $(@D)
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
	@ln -sf $^ $@

$(NDNA_EXTLIBDIR)/%.jar: $(ABS_CACHE)/noarch/%.jar
	mkdir -p $(@D)
	@ln -sf $^ $@

# --------------------------------------------------------------------
# general purpose noarch file sets
# for now activated only for doc modules since bad side effects have 
# been encoutered on some projects (conflicting with smart responder
# models code generation).
$(ABSWS_NA_EXTLIBDIR)/%/.dir: $(ABS_CACHE)/noarch/%.tar.gz
	@$(ABS_PRINT_info) "Unpacking data file set : $*"
	@tar -xzf $^ -C $(ABSWS_NA_EXTLIBDIR) && touch $@

$(ABSWS_NDNA_EXTLIBDIR)/%/.dir: $(ABS_CACHE)/noarch/%.tar.gz
	@$(ABS_PRINT_info) "Unpacking data file set : $*"
	@tar -xzf $^ -C $(ABSWS_NDNA_EXTLIBDIR) && touch $@
	
$(NA_EXTLIBDIR)/%/.dir: $(ABSWS_NA_EXTLIBDIR)/%/.dir
	$(call extlib_linkLibrary)

$(NDNA_EXTLIBDIR)/%/.dir: $(ABSWS_NDNA_EXTLIBDIR)/%/.dir
	$(call extlib_linkLibrary)

TRANSUSELIB:=$(USELIB)
DEV_USELIB:=$(filter-out $(DEV_USELIB_IGNORE),$(filter %d,$(USELIB)))
ALLUSELIB:=$(TRANSUSELIB) $(NDUSELIB)
# macro to include lib
# $1 lib dependancy name (name-version)
# $3 lib parent name
# $3 extlib directory path
# $4 variable to use to store libs
define includeExtLib
# the import.mk must not be imported if already imported in EXTLIB
ifeq ($$(filter $1,$$($4) $$(TRANSUSELIB)),)
$$(eval $4+=$1)
include $$(patsubst %,$3/%/import.mk,$1)
else
$$(info $$(shell $(ABS_PRINT_info) "$1 already imported, ignoring new dependency from $2 to $1"))
endif

endef

# macro to include lib
# $1 lib dependancy name (name-version)
# $2 lib parent name
# $3 extlib directory path
# $4 variable to use to store libs
define condIncludeExtLib
$$(eval ADDEDDEPLIST:=$$(ADDEDDEPLIST) "$2"->"$1")
ifeq ($$(filter $(word 1,$(subst -, ,$1))-%,$$(ALLUSELIB)),)
# the lib has not been imported yet
ALLUSELIB+=$1
ifneq ($(filter-out $(DEV_USELIB_IGNORE),$(filter %d,$1)),)
DEV_USELIB+=$1
endif
$(call includeExtLib,$1,$2,$3,$4)
else
ifneq ($(word 2,$(subst -, ,$1)),$$(word 2,$$(subst -, ,$$(filter $(word 1,$(subst -, ,$1))-%,$$(ALLUSELIB)))))
$$(info $$(shell $(ABS_PRINT_warning) "$1 not imported from $2, already imported another version: $$(filter $(word 1,$(subst -, ,$1))-%,$$(ALLUSELIB))"))
DEPENDENCIES_ERROR=true
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
define extlib_import_template
ifneq ($$(filter $(1)-$(2),$$(TRANSUSELIB)),)
$(foreach lib,$3,$(call condIncludeExtLib,$(lib),$(1)-$(2),$(EXTLIBDIR),TRANSUSELIB))
CFLAGS+=-I$(EXTLIBDIR)/$(1)-$(2)/include
LDFLAGS+=-L$(EXTLIBDIR)/$(1)-$(2)/lib -L$(EXTLIBDIR)/$(1)-$(2)/lib64
else
ifneq ($$(filter $(1)-$(2),$$(NA_USELIB)),)
$(foreach lib,$3,$(call condIncludeExtLib,$(lib),$(1)-$(2),$(NA_EXTLIBDIR),NA_USELIB))
CFLAGS+=-I$(NA_EXTLIBDIR)/$(1)-$(2)/include
else
ifneq ($$(filter $(1)-$(2),$$(NDUSELIB)),)
$(foreach lib,$3,$(call condIncludeExtLib,$(lib),$(1)-$(2),$(NDEXTLIBDIR),NDUSELIB))
CFLAGS+=-I$(NDEXTLIBDIR)/$(1)-$(2)/include
LDFLAGS+=-L$(NDEXTLIBDIR)/$(1)-$(2)/lib -L$(NDEXTLIBDIR)/$(1)-$(2)/lib64
else
ifneq ($$(filter $(1)-$(2),$$(NDNA_USELIB)),)
$(foreach lib,$3,$(call condIncludeExtLib,$(lib),$(1)-$(2),$(NDNA_EXTLIBDIR),NDNA_USELIB))
CFLAGS+=-I$(NDNA_EXTLIBDIR)/$(1)-$(2)/include
endif
endif
endif
endif

endef

# list of import makefile from external libraries declared in module
# configuration only if not requesting clean or cleanabs target. In this case,
# we don't care importing the dependencies.
ifneq ($(MAKECMDGOALS),clean)
ifneq ($(MAKECMDGOALS),cleanabs)
EXTLIBMAKES=$(patsubst %,$(EXTLIBDIR)/%/import.mk,$(TRANSUSELIB)) $(patsubst %,$(NDEXTLIBDIR)/%/import.mk,$(NDUSELIB)) $(patsubst %,$(NDNA_EXTLIBDIR)/%/import.mk,$(NDNA_USELIB)) $(patsubst %,$(NA_EXTLIBDIR)/%/import.mk,$(NA_USELIB))
include $(EXTLIBMAKES)
endif
endif

# external libraries are expected before starting compilation.
$(OBJS): $(EXTLIBMAKES)

# --------------------------------
# Print warning or fail according strict checking mode when
# USELIB check has detected inconsistencies
# --------------------------------
ifneq ($(MAKECMDGOALS),checkdep)
ifeq ($(DEPENDENCIES_ERROR),true)
ifneq ($(ABS_STRICT_DEP_CHECK),)
$(info $(shell $(ABS_PRINT_error) "================================================================"))
$(info $(shell $(ABS_PRINT_error) "                     ERROR"))
$(info $(shell $(ABS_PRINT_error) "Same lib used with different version, check USELIB definitions."))
$(info $(shell $(ABS_PRINT_error) "USELIB is: $(USELIB)"))
$(info $(shell $(ABS_PRINT_error) "Launch 'make checkdep' to see dep graph."))
$(info $(shell $(ABS_PRINT_error) "================================================================"))
ABS_FATAL:=true
else
all-impl::
	@$(ABS_PRINT_warning) "================================================================"
	@$(ABS_PRINT_warning) "                           WARNING"
	@$(ABS_PRINT_warning) "Same lib used with different version, check USELIB definitions."	
	@$(ABS_PRINT_warning) "USELIB is: $(USELIB)"
	@$(ABS_PRINT_warning) "Launch 'make checkdep' to see depenedency graph."
	@$(ABS_PRINT_warning) "================================================================"
endif
endif

ifneq ($(DEV_USELIB),)
ifneq ($(ABS_STRICT_DEP_CHECK),)
$(info $(shell $(ABS_PRINT_error) "================================================================"))
$(info $(shell $(ABS_PRINT_error) "                     ERROR"))
$(info $(shell $(ABS_PRINT_error) "Dependencies include non tagged libraries."))
$(info $(shell $(ABS_PRINT_error) "$(DEV_USELIB)"))
$(info $(shell $(ABS_PRINT_error) "Launch 'make checkdep' to see the full dependency graph."))
$(info $(shell $(ABS_PRINT_error) "================================================================"))
ABS_FATAL:=true
else
all-impl::
	@$(ABS_PRINT_warning) "================================================================"
	@$(ABS_PRINT_warning) "                           WARNING"
	@$(ABS_PRINT_warning) "Dependencies include non tagged libraries."	
	@$(ABS_PRINT_warning) "$(DEV_USELIB)"
	@$(ABS_PRINT_warning) "Launch 'make checkdep' to see the full dependency graph."
	@$(ABS_PRINT_warning) "================================================================"
endif
endif
endif

## Targets:
##  - checkdep: show currently defined dependencies (full graph including 
##    dependencies of dependencies).
ifneq ($(USELIB),)
$(BUILDROOT)/$(APPNAME)_deps.dot: $(PRJROOT)/app.cfg
	@$(ABS_PRINT_info) "Generating project dependency graph."
	@echo "digraph deps {" > $@
	@printf ' $(foreach dep,$(USELIB),"$(APPNAME)-$(VERSION)"->"$(dep)"\n)' >> $@
	@printf ' $(foreach dep,$(ADDEDDEPLIST),$(dep)\n)' >> $@
	@echo "}" >> $@
	@dot -Tpng $@ > $@.png

checkdep: $(BUILDROOT)/$(APPNAME)_deps.dot
	@$(ABS_PRINT_info) "Launching image viewer to display the generated dependency graph $^.png."
	@$(ABS_PRINT_info) "Close image viewer to continue or hit Ctrl-C to stop here."
	@xdot $^.png 2>/dev/null || eog $^.png 2>/dev/null || xdg-open $^.png 2>/dev/null || $(ABS_PRINT_error) "No image viewer found (expected one of: xdot, eog, xdg-open)"
else
checkdep:
	@$(ABS_PRINT_info) "No dependencies set in USELIB project parameter."
endif
endif
