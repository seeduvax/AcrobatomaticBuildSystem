## ---------------------------------------------------------------------
## C/C++ : cppcheck
## ---------------------------------------------------------------------
## Targets
##  - cppcheck: launch cppcheck and generate report
## 
## Variables
##  CPPCHECK_SUPPRESS: checks to ignore by cppcheck
##  CPPCHECK_TESTS_SUPPRESS: checks to ignore by cppcheck for sources in test directory
##  CPPCHECK_EXTLIBS_SUPPRESS: checks to ignore by cppcheck from extlibs headers
##  CPPCHECK_ARGS: additionals arguments for cppcheck binary
##  CPPCHECK_VERSION: version of cppcheck (default is 2.17.0)
##  CPPCHECK_SRCS: files or directories containing sources to ananlyze (src test are already presents)
##  CPPCHECK_TIME: indicates if the check duration must be shown
##  CPPCHECK_EXCLUDE_EXTLIBS: List of externals libs to exclude of analyze.
## 

ifeq ($(MAKECMDGOALS),cppcheck)

CPPCHECK_VERSION?=2.17.0
CPPCHECK_LIBRARY=cppcheck-$(CPPCHECK_VERSION)
NDUSELIB+=$(CPPCHECK_LIBRARY)

CPPCHECK_DIR=$(call GetExtLibDir,$(NDEXTLIBDIR),$(CPPCHECK_LIBRARY))
CPPCHECK_BINARY?=$(CPPCHECK_DIR)/bin/cppcheck

CPPCHECK_SUPPRESS_FILE=$(OBJDIR)/cppcheck_suppress.txt
CPPCHECK_INCLUDES_FILE=$(OBJDIR)/cppcheck_includes.txt

CPPCHECK_BUILD_DIR=$(OBJDIR)/cppcheck_build_dir

CPPCHECK_SUPPRESS+=unmatchedSuppression missingIncludeSystem

CPPCHECK_TESTS_SUPPRESS+=uselessOverride
# define each suppress because need preprocessorErrorDirective to avoid stop of analyze.
CPPCHECK_EXTLIBS_SUPPRESS+=$(CPPCHECK_SUPPRESS)
CPPCHECK_EXTLIBS_SUPPRESS+=missingOverride cstyleCast passedByValue uninitMemberVarPrivate unusedPrivateFunction duplInheritedMember
CPPCHECK_EXTLIBS_SUPPRESS+=duplicateValueTernary operatorEqVarError unreadVariable uninitMemberVar virtualCallInConstructor constParameterPointer
CPPCHECK_EXTLIBS_SUPPRESS+=constVariablePointer uselessOverride

CPPCHECK_ARGS+=--enable=all --inline-suppr --error-exitcode=1 --report-progress
CPPCHECK_ARGS+=$(sort $(filter -D%,$(CXXFLAGS) $(CFLAGS)))
CPPCHECK_ARGS+=--cppcheck-build-dir=$(CPPCHECK_BUILD_DIR)
CPPCHECK_ARGS+=--suppressions-list=$(CPPCHECK_SUPPRESS_FILE)

# indicates if the cppcheck duration must be shown
CPPCHECK_TIME?=true

# paths to extlibs to not include in includes file.
CPPCHECK_EXCLUDE_EXTLIBS_INCLUDES=$(foreach el,$(sort $(CPPCHECK_EXCLUDE_EXTLIBS)),$(wildcard $(EXTLIBDIR)/$(el)/*/include $(NA_EXTLIBDIR)/$(el)/*/include $(NDEXTLIBDIR)/$(el)/*/include $(NDNA_EXTLIBDIR)/$(el)/*/include))
CPPCHECK_EXTLIBS_ALL_INCLUDES=$(subst //,/,$(wildcard $(EXTLIBDIR)/*/*/include $(NA_EXTLIBDIR)/*/*/include $(NDEXTLIBDIR)/*/*/include $(NDNA_EXTLIBDIR)/*/*/include $(patsubst -I%,%,$(filter -I%,$(CXXFLAGS) $(CFLAGS)))))
CPPCHECK_EXTLIBS_INCLUDES=$(filter-out $(CPPCHECK_EXCLUDE_EXTLIBS_INCLUDES),$(sort $(CPPCHECK_EXTLIBS_ALL_INCLUDES)))

# /usr/include must not be included otherwise cppcheck can fail without analyzing code.
# generation of RES_HEADER if resources files are needed to generate res.h.
$(CPPCHECK_INCLUDES_FILE): module.cfg $(PRJROOT)/app.cfg
	@echo "" > $@.tmp
	@$(foreach mod,$(sort $(INCLUDE_PROJ_MODS) $(INCLUDE_TESTMODS_PROJ) $(MODNAME)),$(if $(wildcard $(PRJROOT)/$(mod)/include),echo $(PRJROOT)/$(mod)/include >> $@.tmp;))
	@$(foreach path,$(CPPCHECK_EXTLIBS_INCLUDES),echo "$(path)" >> $@.tmp;)
	@mv $@.tmp $@
	
$(CPPCHECK_SUPPRESS_FILE): module.cfg $(PRJROOT)/app.cfg
	@echo "" > $@.tmp
	@$(if $(filter preprocessorErrorDirective,$(CPPCHECK_EXTLIBS_SUPPRESS)),$(ABS_PRINT_warning) "preprocessorErrorDirective suppression present for ext libs. This can hide errors while checking cpp")
	@$(if $(filter preprocessorErrorDirective,$(CPPCHECK_SUPPRESS)),$(ABS_PRINT_warning) "preprocessorErrorDirective suppression present. This can hide errors while checking cpp")
	@$(foreach suppr,$(sort $(CPPCHECK_EXTLIBS_SUPPRESS)),echo "$(suppr):$(PRJROOT)/build/extlib/*" >> $@.tmp;)
	@$(foreach suppr,$(sort $(CPPCHECK_SUPPRESS)),echo $(suppr) >> $@.tmp;)
	@$(foreach suppr,$(sort $(CPPCHECK_TESTS_SUPPRESS)),echo $(suppr):test/* >> $@.tmp;)
	@mv $@.tmp $@

.PHONY: $(OBJDIR)/cppcheck.log
$(OBJDIR)/cppcheck.log: $(CPPCHECK_INCLUDES_FILE) $(CPPCHECK_SUPPRESS_FILE) $(if $(RESSRC),$(RES_HEADER))
	@mkdir -p $(CPPCHECK_BUILD_DIR)
	@$(if $(filter true,$(CPPCHECK_TIME)),time) $(CPPCHECK_BINARY) --includes-file=$< --output-file=$@ $(CPPCHECK_ARGS) $(wildcard src test $(CPPCHECK_SRCS)) || $(ABS_PRINT_error) "Errors found while analyzing cpp code"

ifneq ($(filter %.cpp %.c,$(SRCFILES))$(CPPCHECK_SRCS),)
cppcheck: $(OBJDIR)/cppcheck.log
	@$(ABS_PRINT_info) "File $< generated"

else
cppcheck:
	@$(ABS_PRINT_warning) "Cannot execution cppcheck because no cpp/c source files found"

endif

endif #ifeq ($(MAKECMDGOALS),cppcheck)