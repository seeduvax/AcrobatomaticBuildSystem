##
## ------------------------------------------------------------------------
## Dependencies management
## ------------------------------------------------------------------------

GETLIB?=$(ABSROOT)/core/getdist.sh
ECLIPSE_PRJ=$(PRJROOT)/.project
DEPTOOL:=$(ABSROOT)/core/deptool.bash

# tell the bootstrap makefile to not define its own default download rule.
ABS_DEPDOWNLOAD_RULE_OVERLOADED:=1
# download files from repository
$(ABS_CACHE)/%:
	@mkdir -p $(@D)
	@afile=$(patsubst $(ABS_CACHE)/%,%,$@) ;\
	for repo in $(ABS_REPO) ; do \
		$(ABS_PRINT_info) "Fetching $$afile from $$repo" ; \
		case $$repo in \
			file://*) srcfile=`echo "$$repo" | cut -f 2 -d ':'`/$$afile ; \
				test -f $$srcfile && ln -sf $$srcfile $@ ; \
				test -r $@ && exit 0 || \
				$(ABS_PRINT_warning) "$$afile not available from $$repo";; \
			*) wget -q --no-check-certificate $$repo/$$afile -O $@ && exit 0 || \
				$(ABS_PRINT_warning) "$$afile not available from $$repo";; \
		esac \
	done ; $(ABS_PRINT_error) "Can't fetch $$afile." && exit 1

# unpack external libraries when app.cfg is more recent than the download
# since it may have been edited to change USELIB.
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

define condIncludeExtLib
ifeq ($$(filter $1,$$(USELIB)),)
ifeq ($$(filter $(word 1,$(subst -, ,$1))-%,$$(USELIB)),)
USELIB+=$1
include $$(patsubst %,$(EXTLIBDIR)/%/import.mk,$1)
else
$$(info $$(shell $(ABS_PRINT_warning) "$1 not imported from $2, already imported another version: $$(filter $(word 1,$(subst -, ,$1))-%,$$(USELIB))"))
endif
else
$$(info $$(shell $(ABS_PRINT_info) "$1 already imported, ignoring new dependency from $2 to $1"))
endif

endef

# macro to be expansed at external lib inclusion.
# $1 lib name
# $2 lib version
# $3 lib's dependancies.
define extlib_import_template
$(eval $(foreach lib,$3,$(call condIncludeExtLib,$(lib),$(1)-$(2))))
CFLAGS+=-I$(EXTLIBDIR)/$(1)-$(2)/include
LDFLAGS+=-L$(EXTLIBDIR)/$(1)-$(2)/lib -L$(EXTLIBDIR)/$(1)-$(2)/lib64
endef

# list of import makefile from external libraries declared in module configuration
EXTLIBMAKES=$(patsubst %,$(EXTLIBDIR)/%/import.mk,$(USELIB))
include $(EXTLIBMAKES)

# external libraries are expected before starting compilation.
$(OBJS): $(EXTLIBMAKES)

# --------------------------------
# USELIB content check helper vars
# --------------------------------
S_USELIB=$(sort $(USELIB))
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
checkdep:
	@APPNAME="$(APPNAME)" VERSION="$(VERSION)" EXTLIBDIR="$(EXTLIBDIR)" PRJROOT="$(PRJROOT)" $(DEPTOOL)
