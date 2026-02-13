##
## --------------------------------------------------------------------
## C/C++ Unit test services
## ------------------------------------------------------------------------
##
## Test services variables
##
##  - CPP_UNIT_TESTER: Unit tester, choose one of:
##    - cppunit
##    - googletest
##    - geod
##    cppunit is the default.
##  - TUSEMOD: The other mods of the project to link for the tests.
##  - TLINKLIB: List of libraries to link for tests.
##  - TCFLAGS: CFLAGS used for tests compilation
##  - TLDFLAGS: LDFLAGS used for tests linkage
##  - TDISABLE_SRC: List of files in test directory to not compile
##
## ------------------------------------------------------------------------

CPP_UNIT_TESTER?=cppunit
# include selected test tool definitions
ifeq ($(word 1,$(MAKECMDGOALS)),newtest)
TESTNAME=$(word 2,$(MAKECMDGOALS))$(T)
endif
include $(ABSROOT)/core/xunit/$(CPP_UNIT_TESTER).mk

# valgrind
VALGRIND=valgrind

# Target definition.
ifeq ($(ISWINDOWS),true)
  ifeq ($(DYNAMIC_LIB),true)
     TCYGTARGET=$(TTARGETDIR)/t_$(CYGTARGET)
  else
     TCYGTARGET=$(TTARGETDIR)/t_$(subst $(SOEXT),$(AREXT),$(CYGTARGET))
  endif
  TTARGETFILE=$(TCYGTARGET)
else
  ifeq ($(DYNAMIC_LIB),true)
     TTARGETFILE=$(TTARGETDIR)/t_$(TARGET)
  else
     TTARGETFILE=$(TTARGETDIR)/t_$(subst $(SOEXT),$(AREXT),$(TARGET))
  endif
endif
TARGETFILES+=$(TTARGETFILE)

ifeq ($(VALGRIND_XML),true)
	VALGRIND_ARGS+=--xml=yes --xml-file=$(TTARGETDIR)/$(MODNAME)_valgrind_result.xml
endif

T_ALL_DEPENDENCIES=$(call getDependenciesByTransitivity,$(call getLibrariesNameFromLinklib,$(TLINKLIB)) $(INCLUDE_TESTMODS) $(patsubst %,$(APPNAME)_%,$(TESTUSEMOD)))

# objects to be generated from test classes.
TALLSRCFILES=$(call find,test,*.cpp *.c)
TSRCFILES=$(filter-out $(patsubst %,test/%,$(TDISABLE_SRC)),$(TALLSRCFILES))
TCPPOBJS=$(patsubst test/%.cpp,$(OBJDIR)/test/%.o,$(filter %.cpp,$(TSRCFILES))) \
		$(patsubst test/%.c,$(OBJDIR)/test/%.o,$(filter %.c,$(TSRCFILES)))

INCLUDE_TESTMODS_PROJ=$(filter-out $(MODNAME),$(patsubst $(APPNAME)_%,%,$(filter $(PROJECT_INC_MODS),$(T_ALL_DEPENDENCIES))))
# compiler options specific to test
TCFLAGS+=$(patsubst %,-I$(PRJROOT)/%/include,$(INCLUDE_TESTMODS_PROJ))

# linker options specific to test
TLDFLAGS+=-L$(TRDIR)/$(SODIR)
ifeq ($(DYNAMIC_LIB),true)
TLDFLAGS+=$(patsubst %,-l%,$(call GetExistingModGeneratedSO,$(TESTUSEMOD)))
endif
ifeq ($(STATIC_LIB),true)
TLDFLAGS+=$(patsubst %,-l%,$(call GetExistingModGeneratedArchive,$(TESTUSEMOD)))
endif
TLDFLAGS+=$(patsubst %,-l%,$(TLINKLIB))

INCLUDE_TESTMODS_EXT=$(filter-out $(PROJECT_INC_MODS),$(sort $(T_ALL_DEPENDENCIES)))

INCLUDE_TESTMODS_EXT_LOOKING_PATHS=$(sort $(foreach modExt,$(INCLUDE_TESTMODS_EXT),$(_module_$(modExt)_dir) $(_app_$(modExt)_dir)))
INCLUDE_TESTMODS_EXT_CPATHS=$(foreach path,$(INCLUDE_TESTMODS_EXT_LOOKING_PATHS),$(wildcard $(path)/include))
TCFLAGS+=$(foreach extPath,$(INCLUDE_TESTMODS_EXT_CPATHS),-I$(extPath))

INCLUDE_TESTMODS_EXT_LDPATHS+=$(foreach path,$(INCLUDE_TESTMODS_EXT_LOOKING_PATHS),$(filter-out %/library.json,$(wildcard $(path)/lib*)))
TLDFLAGS+=$(foreach extPath,$(INCLUDE_TESTMODS_EXT_LDPATHS),-L$(extPath))

# adaptation to module type
ifeq ($(MODTYPE),library)
# when target is a library, test lib must link with target
ifeq ($(APPNAME),$(MODNAME))
	TLDFLAGS+=-l$(APPNAME)
else
	TLDFLAGS+=-l$(APPNAME)_$(MODNAME)
endif
else
ifeq ($(MODTYPE),exe)
# when the target is an exe, the test lib must include the objects made
# to build the exe
# TODO: a bit strange, why not just reuse OBJS?
	TCPPOBJS+=$(patsubst src/%.cpp,$(OBJDIR)/bintest/%.o,$(filter %.cpp,$(SRCFILES)))  $(OBJDIR)/vinfo.o
# use links of executable.
	TLDFLAGS+=$(filter -l%,$(LDFLAGS))
endif
	TLDFLAGS+=-shared -ldl
endif

# define include path and namespace according wether module is default module
ifeq ($(APPNAME),$(MODNAME))
	TINC_PATH=$(APPNAME)
	TNAMESPACE=$(APPNAME)
else
	TINC_PATH=$(APPNAME)/$(MODNAME)
	TNAMESPACE=$(APPNAME)::$(MODNAME)
endif

# add extra libs required only for testing

TLDLIBP=$(LDLIBP):$(subst $(_space_),:,$(patsubst -L%,%,$(filter -L%,$(TLDFLAGS))))

-include $(patsubst %.o,%.o.d,$(TCPPOBJS))
# ---------------------------------------------------------------------
# transformation rules specific to tests.
# test cpp files compilation
$(OBJDIR)/test/%.o: test/%.cpp
	@$(ABS_PRINT_info) "Compiling test $< ..."
	@mkdir -p $(@D)
	@$(call writeToBuildLogs,$(CPPC) $(CXXFLAGS) $(CFLAGS) $(TCFLAGS) $(TCXXFLAGS) -c $< -o $@)
	$(pre_compile_cpp_test)
ifeq ($(wildcard $(patsubst %.o,%.h,$@)),$(patsubst %.o,%.h,$@))
	@$(CPPC) $(CXXFLAGS) $(TCXXFLAGS) $(CFLAGS) $(TCFLAGS) -include $(patsubst %.o,%.h,$@) $(GEN_DEP_FLAGS) -c $< -o $@
else
	@$(CPPC) $(CXXFLAGS) $(TCXXFLAGS) $(CFLAGS) $(TCFLAGS) $(GEN_DEP_FLAGS) -c $< -o $@
endif

ifeq ($(ISWINDOWS),true)
	$(win-patch-dep)
endif

$(OBJDIR)/test/%.o: test/%.c
	@$(ABS_PRINT_info) "Compiling test $< ..."
	@mkdir -p $(@D)
	$(pre_compile_c_test)
	@$(call executeAndLogCmd,$(CC) $(CFLAGS) $(TCFLAGS) $(GEN_DEP_FLAGS) -c $< -o $@)
ifeq ($(ISWINDOWS),true)
	$(win-patch-dep)
endif

ifneq ($(PREPROC_ONLY),true)
$(OBJDIR)/bintest/%.o: $(OBJDIR)/%.o
	@$(ABS_PRINT_info) "Checking $(@F) symbols for Test Mode..."
	@mkdir -p $(@D)
	@$(call executeAndLogCmd,$(OBJCOPY) --redefine-sym main=__Exec_Main_Stubbed_for_unit_tests__ $< $@)
else
$(OBJDIR)/bintest/%.o: $(OBJDIR)/%.o
	@-cp $< $@ 2> /dev/null
endif

ifneq ($(filter exe library,$(MODTYPE)),)
  ifeq ($(DYNAMIC_LIB),true)
     TTARGETFILEDEP:=$(TARGETFILE)
  else
     TTARGETFILEDEP:=$(subst $(SOEXT),$(AREXT),$(TARGETFILE))
  endif
endif

# link main lib dependencies too (in case the main lib is not directly used.)
TLDFLAGS_L=$(filter -l%,$(TLDFLAGS) $(LDFLAGS))

ifneq ($(PREPROC_ONLY),true)
ifneq ($(ISWINDOWS),true)
define ld-test
@$(ABS_PRINT_info) "Linking $@ ..."
@$(call updateOptionsAndFlags, OPTIONSANDFLAGS, $(LDFLAGS), $(TLDFLAGS), $@)
@$(call writeToBuildLogs,t_$(MODNAME) linked to $(sort $(patsubst -l%,%,$(TLDFLAGS_L))))
@$(call executeAndLogCmd,$(LD) -o $@ $(TCPPOBJS) $(OPTIONSANDFLAGS))
endef
else
define ld-test
@$(ABS_PRINT_info) "Linking $(TCYGTARGET) ..."
@$(call updateOptionsAndFlags, OPTIONSANDFLAGS, $(LDFLAGS), $(TLDFLAGS), $@)
@$(call writeToBuildLogs,t_$(MODNAME) linked to $(sort $(patsubst -l%,%,$(TLDFLAGS_L))))
@$(call executeAndLogCmd,$(LD) -o $(TCYGTARGET) $(call getWindowsLibLDFlags,$@,$(TCPPOBJS)) $(OPTIONSANDFLAGS))
endef
endif
else
define ld-test
$(ld-command-preproc)
endef
endif

# link test target from test objects.
$(TTARGETFILE): $(TCPPOBJS) $(TTARGETFILEDEP) $(LD_SCRIPT)
	@mkdir -p $(@D)
	@$(ld-test) $(LD_APPEND)

# CPPUNIT must be added before following rules to recompute $(EXTLIBMAKES)
NDUSELIB+=$(CPPUNIT)
ifneq ($(XARCH),)
# TODO: Unsure, NDXA_USELIB not define previously (not well reported everything from Antoine)...
NDXA_USELIB+=$(CPP_UNIT_TESTER_LIB)
else
NDUSELIB+=$(CPP_UNIT_TESTER_LIB)
endif

# ---------------------------------------------------------------------
# Extra dependencies
# ---------------------------------------------------------------------
# Generating test object need cppunit libs and tools to be availables
$(TCPPOBJS): $(EXTLIBMAKES)

ifneq ($(ARE_TESTS_AVAILABLE),)

# Variable to handle the filter of some test files defined in FILTER_TEST_FILES.
# The files in FILTER_TEST_FILES must start with 'test/'.
# The modified files are put in FILTERED_DIRECTORY.
FILTERED_DIRECTORY=$(TTARGETDIR)/Filtered
FILTERED_TEST_FILES_OUTPUT=$(patsubst test/%,$(FILTERED_DIRECTORY)/%,$(FILTER_TEST_FILES))

$(FILTERED_DIRECTORY)/%: test/%
	@$(ABS_PRINT_info) "Copying test file to filter $< ..."
	@mkdir -p $(@D)
	@cp $< $@
	@/bin/bash -c "echo \"Filtering $@ ...\"; $(call filterCmds, $@)"

# ---------------------------------------------------------------------
##
## Test targets:
##
##  - testbuild: builds tests but do not run them.
.PHONY:	testbuild
testbuild::	$(TTARGETFILE) $(FILTERED_TEST_FILES_OUTPUT)

define pre-test
@test ! -d test || mkdir -p $(TTARGETDIR)
@test ! -d test || rm -f $(TEST_REPORT_PATH)
endef

# Path to dll for Wine execution.
WINEFULLPATH=$(TRDIR)/bin;$(subst :,;,$(TLDLIBP))

# macro to launch the test
define exec-test
@$(if $(filter true,$(ISWINDOWS)),,$(RUNTIME_PROLOG))
@test ! -d test \
	|| (set -o pipefail; PATH="$(RUNPATH)" LD_LIBRARY_PATH="$(TLDLIBP)" WINEPATH="$(WINEFULLPATH);$$WINEPATH" TRDIR="$(TRDIR)" TTARGETDIR="$(TTARGETDIR)" LD_PRELOAD="$(TLDPRELOADFORMATTED)" $(RUNTIME_ENV) $1 $(ARCH_EXECUTOR) $(TEST_RUNNER_CMD) $(TTARGETFILE) $(TEST_RUNNER_ARG_XML)$(TEST_REPORT_PATH) $(RUNARGS) $(patsubst %,+f %,$(T)) $(TARGS) 2>&1 | tee $(TTARGETDIR)/$(APPNAME)_$(MODNAME).stdout) \
	|| $(ABS_PRINT_error) "Tests execution failed. $(if $(TIMEOUT),Timeout=$(TIMEOUT)s)"
@$(if $(filter true,$(ISWINDOWS)),,$(RUNTIME_EPILOG))
endef

define run-test
$(pre-test)
$(exec-test)
$(post-test)
endef

##  - test: alias for check
test:: testbuild
	$(call run-test,$(TIMEOUTCMD))

##  - check [RUNARGS="<arg> [<arg>]*] [T=<test name>]: builds and runs tests
##         When only one test shall be run, use optionnal T variable argument.
check:: test

##  - valgrindtest: run tests from valgrind for profiling.
.PHONY: valgrindtest
ifeq ($(ACTIVATE_SANITIZER),true)
valgrindtest:: testbuild
	@$(ABS_PRINT_error) "Cannot run valgrind with ACTIVATE_SANITIZER=true"

else
valgrindtest:: testbuild
	$(call run-test, $(VALGRIND) $(VALGRIND_ARGS))

endif

##  - debugcheck [RUNARGS="<arg> [<arg>]*": run test from gdb debugger
# TODO add cygwin support

GDBCMDTEST:=$(OBJDIR)/gdb-$(MODNAME).test

.PHONY: $(GDBCMDTEST)
$(GDBCMDTEST): testbuild
	@$(ABS_PRINT_info) "Generating gdb test script $(GDBCMDTEST)"
	@mkdir -p $(@D)
	@echo 'set environment LD_LIBRARY_PATH=$(TLDLIBP)' > $(GDBCMDTEST)
	@echo 'set environment TRDIR=$(TRDIR)' >> $(GDBCMDTEST)
	@echo 'set environment TTARGETDIR=$(TTARGETDIR)' >> $(GDBCMDTEST)
	@echo 'set args $(RUNARGS) $(patsubst %,+f %,$(T)) $(TARGS) $(TTARGETFILE)' >> $(GDBCMDTEST)
	@echo 'file $(CPPUNIT_DIR)/bin/$(TESTRUNNER)' >> $(GDBCMDTEST)
	@printf "define runtests\nrun\nend\n" >> $(GDBCMDTEST)


.PHONY: debugcheck
debugcheck: $(GDBCMDTEST)
	@$(ABS_PRINT) "use" "Use runtests command to launch tests from gdb"
	@PATH="$(RUNPATH)" gdb -x $<

GDBSERVER_PORT?=9091
##  - remotedebugtest [RUNARGS="<arg> [<arg>]*": run test from gdbserver debugger] [GDBSERVER_PORT=9091 : default gdbserver port]
.PHONY: remotedebugtest
remotedebugtest: testbuild
	@PATH="$(RUNPATH)" LD_LIBRARY_PATH="$(TLDLIBP)" TRDIR="$(TRDIR)" TTARGETDIR="$(TTARGETDIR)" gdbserver :$(GDBSERVER_PORT) $(CPPUNIT_DIR)/bin/$(TESTRUNNER) $(TTARGETFILE) $(RUNARGS) $(patsubst %,+f %,$(T)) $(TARGS)

##  - debugtest: alias for debugcheck
.PHONY: debugtest
debugtest: debugcheck

else
# when no test are available, making test shall at least build the module
test::
	@$(ABS_PRINT_warning) "no test for this module"

debugtest: test

valgrindtest:: test

debugcheck: test

endif

define gen_vsdebugtest
{
  "version": "0.2.0",
  "configurations": [
      {
        "name": "make remotedebugtest",
        "type": "cppdbg",
        "request": "launch",
        "program": "$(TTARGETFILE)",
        "miDebuggerServerAddress": "localhost:$(GDBSERVER_PORT)",
        "args": [],
        "stopAtEntry": false,
        "cwd": "$(PWD)",
        "environment": [],
        "externalConsole": true,
        "setupCommands": [
          {
              "description": "Enable pretty-printing for gdb",
              "text": "-enable-pretty-printing",
              "ignoreFailures": true
          }
         ],
         "linux": {
         "MIMode": "gdb"
         }
      }
   ]
}
endef
export gen_vsdebugtest

##  - vsdebugtest: print unit tests setup for vscode
.PHONY:	vsdebugtest
vsdebugtest:
	@echo "**** vscode launch configuration: .vscode/launch.json ****"
	@echo "$$gen_vsdebugtest"


##  - edebugtest: print unit tests setup for eclipse
.PHONY:	edebugtest
edebugtest:
	@echo "**** Eclipse debugger setup for tests : ****"
	@echo
	@printf "Application:\t\t"
	@echo "$(patsubst $(PRJROOT)/%,%,$(CPPUNIT_DIR)/bin/$(TESTRUNNER))"
	@printf "Arguments:\t\t"
	@printf "$(patsubst $(PRJROOT)/%,%,$(TTARGETFILE))"
	@echo "$(RUNARGS)  $(patsubst %,+f %,$(T))"
	@echo
	@echo "* Environment (replace native) :"
	@echo
	@printf "PATH\t"
	@echo "$(subst $(eval) ,:,$(foreach entry,$(subst :, ,$(RUNPATH)),$(patsubst $(PRJROOT)/%,%,$(entry))))"
	@printf "LD_LIBRARY_PATH\t"
	@echo "$(subst $(eval) ,:,$(foreach entry,$(subst :, ,$(TLDLIBP)),$(patsubst $(PRJROOT)/%,%,$(entry))))"
	@printf "TRDIR\t\t"
	@echo "$(patsubst $(PRJROOT)/%,%,$(TRDIR))"
	@printf "TTARGETDIR\t"
	@echo "$(patsubst $(PRJROOT)/%,%,$(TTARGETDIR))"

##  - newtest <tested class name>: create a new empty test class
ifeq ($(word 1,$(MAKECMDGOALS)),newtest)

.PHONY: newtest
newtest: $(TEST_SRC_FILES)
	@:

$(TESTNAME):
	@:

endif

clean:: clean-module-test

clean-module-test:
	rm -rf $(TTARGETFILE) $(FILTERED_TEST_FILES_OUTPUT)
	rm -rf $(TTARGETDIR)/$(APPNAME)_$(MODNAME).stdout
	rm -rf $(TEST_REPORT_PATH)


$(OBJDIR)/coverage.info: test
	lcov -c --directory $(OBJDIR) -b . --output-file $(OBJDIR)/coverage.info
	genhtml $(OBJDIR)/coverage.info --output-directory $(OBJDIR)/coverage

coverage:: $(OBJDIR)/coverage.info
	firefox $(OBJDIR)/coverage/index.html &
