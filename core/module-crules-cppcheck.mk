
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

# /usr/include must not be included otherwise cppcheck can fail without analyzing code.
# generation of RES_HEADER if resources files are needed to generate res.h.
$(CPPCHECK_INCLUDES_FILE): module.cfg $(PRJROOT)/app.cfg
	@echo "" > $@.tmp
	@$(foreach el,$(sort $(patsubst -I%,%,$(filter -I%,$(CXXFLAGS) $(CFLAGS)))),echo "$(el)" >> $@.tmp;)
	@$(foreach mod,$(sort $(INCLUDE_PROJ_MODS) $(INCLUDE_TESTMODS_PROJ) $(MODNAME)),$(if $(wildcard $(PRJROOT)/$(mod)/include),echo $(PRJROOT)/$(mod)/include >> $@.tmp;))
	@find -L $(wildcard $(EXTLIBDIR) $(NA_EXTLIBDIR) $(NDEXTLIBDIR) $(NDNA_EXTLIBDIR)) -maxdepth 3 -name include -type d >> $@.tmp
	@mv $@.tmp $@
	
$(CPPCHECK_SUPPRESS_FILE): module.cfg $(PRJROOT)/app.cfg
	@$(if $(filter preprocessorErrorDirective,$(CPPCHECK_EXTLIBS_SUPPRESS)),$(ABS_PRINT_warning) "preprocessorErrorDirective suppression present for ext libs. This can hide errors while checking cpp")
	@$(if $(filter preprocessorErrorDirective,$(CPPCHECK_SUPPRESS)),$(ABS_PRINT_warning) "preprocessorErrorDirective suppression present. This can hide errors while checking cpp")
	@$(foreach suppr,$(sort $(CPPCHECK_EXTLIBS_SUPPRESS)),echo "$(suppr):$(PRJROOT)/build/extlib/*" >> $@.tmp;)
	@$(foreach suppr,$(sort $(CPPCHECK_SUPPRESS)),echo $(suppr) >> $@.tmp;)
	@$(foreach suppr,$(sort $(CPPCHECK_TESTS_SUPPRESS)),echo $(suppr):test/* >> $@.tmp;)
	@$(foreach mod,$(sort $(INCLUDE_PROJ_MODS) $(INCLUDE_TESTMODS_PROJ)),\
		$(foreach suppr,$(sort $(CPPCHECK_EXTLIBS_SUPPRESS)),echo $(suppr):$(PRJROOT)/$(mod)/include/* >> $@.tmp;))
	@mv $@.tmp $@

.PHONY: $(OBJDIR)/cppcheck.log
$(OBJDIR)/cppcheck.log: $(CPPCHECK_INCLUDES_FILE) $(CPPCHECK_SUPPRESS_FILE) $(if $(RESSRC),$(RES_HEADER))
	@mkdir -p $(CPPCHECK_BUILD_DIR)
	@$(if $(filter true,$(CPPCHECK_TIME)),time) $(CPPCHECK_BINARY) --includes-file=$< --output-file=$@ $(CPPCHECK_ARGS) $(wildcard src test) || $(ABS_PRINT_error) "Errors found while analyzing cpp code"


ifneq ($(filter %.cpp %.c,$(SRCFILES)),)
##  - cppcheck: launch cppcheck and generate report
cppcheck: $(OBJDIR)/cppcheck.log
	@$(ABS_PRINT_info) "File $< generated"

else
cppcheck:
	@$(ABS_PRINT_warning) "Cannot execution cppcheck because no cpp/c source files found"

endif

endif #ifeq ($(MAKECMDGOALS),cppcheck)