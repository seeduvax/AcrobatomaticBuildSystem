##
## ------------------------------------------------------------------------
## Dependencies management
## ------------------------------------------------------------------------

ifeq ($(TRDIR),$(BUILDROOT)/$(ARCH)/$(MODE))
EXTLIBDIR?=$(ABSWS)/extlib/$(ARCH)
NA_EXTLIBDIR?=$(ABSWS)/extlib/noarch
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
		*) wget -q $(WGETFLAGS) $$repo/$1 -O $3 && exit 0 || \
			rm -rf $3 ; \
			 $(ABS_PRINT_warning) "$1 not available from $$repo";; \
	esac \
done ; $(ABS_PRINT_error) "Can't fetch $1." ; rm -rf $3 ; exit 1
endef


$(ABS_CACHE)/%:
	@mkdir -p $(@D)
	$(call downloadFromRepos,$*,$(ABS_REPO),$@)

$(EXTLIBDIR)/%/import.mk: $(ABS_CACHE)/$(ARCH)/%.$(ARCH).tar.gz
	@$(ABS_PRINT_info) "Unpacking library : $(patsubst $(EXTLIBDIR)/%/import.mk,%,$@)"
	@$(ABS_PRINT_debug) "$^"
	@if [ -d $(@D)  ]; then chmod -R u+w $(@D) && rm -rf $(@D); fi
	@mkdir -p $(@D)
	@tar -xzf $^ -C $(EXTLIBDIR) && touch $@
	@if [ -f "$(ECLIPSE_PRJ)" ]; then chmod -R a-w $(@D); fi

# unpack external lib that should not be forwarded to dist package
$(NDEXTLIBDIR)/%/import.mk: $(ABS_CACHE)/$(ARCH)/%.$(ARCH).tar.gz
	@$(ABS_PRINT_info) "Unpacking library : $(patsubst $(NDEXTLIBDIR)/%/import.mk,%,$@)"
	@if [ -d $(@D)  ]; then chmod -R u+w $(@D) && rm -rf $(@D); fi
	@mkdir -p $(@D)
	@tar -xzf $^ -C $(NDEXTLIBDIR) && touch $@
	@if [ -f "$(ECLIPSE_PRJ)" ]; then chmod -R a-w $(@D); fi

# same for java libraries
$(NA_EXTLIBDIR)/%.jar: $(ABS_CACHE)/noarch/%.jar
	@mkdir -p $(@D)
	@ln -sf $^ $@

$(NDNA_EXTLIBDIR)/%.jar: $(ABS_CACHE)/noarch/%.jar
	@mkdir -p $(@D)
	@ln -sf $^ $@

# --------------------------------------------------------------------
# general purpose noarch file sets
# for now activated only for doc modules since bad side effects have 
# been encoutered on some projects (conflicting with smart responder
# models code generation).
$(NA_EXTLIBDIR)/%/.dir: $(ABS_CACHE)/noarch/%.tar.gz
	@$(ABS_PRINT_info) "Unpacking data file set : $(patsubst $(NA_EXTLIBDIR)/%/.dir,%,$@)"
	@tar -xzf $^ -C $(NA_EXTLIBDIR) && touch $@

$(NDNA_EXTLIBDIR)/%/.dir: $(ABS_CACHE)/noarch/%.tar.gz
	@$(ABS_PRINT_info) "Unpacking data file set : $(patsubst $(NDNA_EXTLIBDIR)/%/.dir,%,$@)"
	@tar -xzf $^ -C $(NDNA_EXTLIBDIR) && touch $@

TRANSUSELIB:=$(USELIB)
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
$(call includeExtLib,$1,$2,$3,$4)
else
ifneq ($(word 2,$(subst -, ,$1)),$$(word 2,$$(subst -, ,$$(filter $(word 1,$(subst -, ,$1))-%,$$(ALLUSELIB)))))
$$(info $$(shell $(ABS_PRINT_warning) "$1 not imported from $2, already imported another version: $$(filter $(word 1,$(subst -, ,$1))-%,$$(ALLUSELIB))"))
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
ifneq ($$(filter $(1)-$(2),$$(NDUSELIB)),)
$(foreach lib,$3,$(call condIncludeExtLib,$(lib),$(1)-$(2),$(NDEXTLIBDIR),NDUSELIB))
CFLAGS+=-I$(NDEXTLIBDIR)/$(1)-$(2)/include
LDFLAGS+=-L$(NDEXTLIBDIR)/$(1)-$(2)/lib -L$(NDEXTLIBDIR)/$(1)-$(2)/lib64
endif
endif

endef

# list of import makefile from external libraries declared in module
# configuration only if not requesting clean or cleanabs target. In this case,
# we don't care importing the dependencies.
ifneq ($(MAKECMDGOALS),clean)
ifneq ($(MAKECMDGOALS),cleanabs)
EXTLIBMAKES=$(patsubst %,$(EXTLIBDIR)/%/import.mk,$(TRANSUSELIB)) $(patsubst %,$(NDEXTLIBDIR)/%/import.mk,$(NDUSELIB))
include $(EXTLIBMAKES)
endif
endif

# external libraries are expected before starting compilation.
$(OBJS): $(EXTLIBMAKES)

# --------------------------------
# USELIB content check helper vars
# --------------------------------
S_USELIB=$(sort $(TRANSUSELIB))
ifneq ($(TAGRQ),)
ifeq ($(USER),jenkins)
D_USELIB=$(filter %d,$(S_USELIB))
endif
endif
UNV_USELIB=$(foreach uselib,$(S_USELIB),$(word 1,$(subst -, ,$(uselib))))
SUNV_USELIB=$(sort $(UNV_USELIB))

# --------------------------------
# Add message to final target when 
# USELIB check has detected inconsistencies
# --------------------------------
ifeq ($(D_USELIB),)
all-impl::
ifneq ($(UNV_USELIB),$(SUNV_USELIB))
	@$(ABS_PRINT_warning) "================================================================"
	@$(ABS_PRINT_warning) "                           WARNING"
	@$(ABS_PRINT_warning) "Same lib used with different version, check USELIB definitions."	
	@$(ABS_PRINT_warning) "USELIB is: $(S_USELIB)"
ifeq ($(DEBUG_USELIB),)
	@$(ABS_PRINT_warning) "Launch 'make checkdep' to see dep graph."
endif
	@$(ABS_PRINT_warning) "================================================================"
ifneq ($(DEBUG_USELIB),)
	@make checkdep
endif
endif
else
all-impl::
	@$(ABS_PRINT_error) "================================================================"
	@$(ABS_PRINT_error) "Can't build tagged version of $(APPNAME), untagged library in use!"
	@$(ABS_PRINT_error) "Untagged libs found are: $(D_USELIB)" 
	@$(ABS_PRINT_error) "================================================================"
	@exit 1
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
	@$(ABS_PRINT_info) "No dependancies set in USELIB project parameter."
endif
