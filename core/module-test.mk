## 
## --------------------------------------------------------------------
## C/C++ Unit test services
## ------------------------------------------------------------------------
## 
## Test services variables
## 
## - CPPUNIT: cppunit version. Default is set accorging your gcc version
##    - 1.14.0 for gcc >= 6.0
##    - 1.12.1 for gcc < 6.0
## 
## ------------------------------------------------------------------------
## 
CC_VERSION_GE6:=$(shell [ `echo "$(CC_VERSION)" | cut -f1 -d.` -ge 6 ] && echo true || echo false)
ifeq ($(CC_VERSION_GE6),true)
CPPUNIT?=cppunit-1.14.0
else
CPPUNIT?=cppunit-1.12.1
endif

TESTRUNNER=ctrunner
TXTXSL=xunit2txt.xsl
TIMEOUT?=300
ifeq ($(COLORS_TCAP),yes)
TIMEOUTCMD:=
else
TIMEOUTCMD:=timeout $(TIMEOUT)
endif

CFLAGS+=-I$(EXTLIBDIR)/$(CPPUNIT)/include
LDFLAGS+=-L$(EXTLIBDIR)/$(CPPUNIT)/$(SODIR)

# valgrind
VALGRIND=valgrind

# Target definition.
TTARGETFILE=$(TTARGETDIR)/t_$(TARGET)
ifeq ($(ISWINDOWS),true)
TCYGTARGET=$(TTARGETDIR)/t_$(CYGTARGET)
endif

ifeq ($(VALGRIND_XML),true)
	VALGRIND_ARGS+=--xml=yes --xml-file=$(TTARGETDIR)/$(MODNAME)_valgrind_result.xml
endif

# objects to be generated from test classes.
TALLSRCFILES=$(shell find test/ -name '*.cpp' -o -name '*.c' 2>/dev/null)
TSRCFILES=$(filter-out $(patsubst %,test/%,$(TDISABLE_SRC)),$(TALLSRCFILES))
#TSRCFILES=$(shell find test/ -name '*.cpp' 2>/dev/null)
TCPPOBJS=$(patsubst test/%.cpp,$(OBJDIR)/test/%.o,$(filter %.cpp,$(TSRCFILES))) \
		$(patsubst test/%.c,$(OBJDIR)/test/%.o,$(filter %.c,$(TSRCFILES)))

# compiler options specific to test
TCFLAGS+=$(patsubst %,-I../%/include,$(TESTUSEMOD))

INCLUDE_PROJ_TESTMODS=$(patsubst $(APPNAME)_%,%,$(filter $(PROJECT_MODS),$(sort $(ABS_INCLUDE_TESTMODS))))

# linker options specific to test
TLDFLAGS+=-L$(TRDIR)/$(SODIR)  $(patsubst %,-l$(APPNAME)_%,$(TESTUSEMOD)) -lcppunit $(patsubst %,-l%,$(TLINKLIB))
TLDFLAGS+=$(patsubst %,-L$(TRDIR)/$(SODIR),$(TESTUSEMOD))
TLDFLAGS+=$(foreach mod,$(INCLUDE_PROJ_TESTMODS),-L$(TRDIR)/$(SODIR))

TCFLAGS+=$(patsubst %,-I$(PRJROOT)/%/include,$(INCLUDE_PROJ_TESTMODS))
TCFLAGS+=$(patsubst %,-I$(TRDIR)/include,$(INCLUDE_PROJ_TESTMODS))

INCLUDE_TESTMODS_EXT=$(filter-out $(PROJECT_MODS),$(sort $(ABS_INCLUDE_TESTMODS))) $(ABS_INCLUDE_TESTMODS) $(TLINKLIB)

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
	TCPPOBJS+=$(patsubst src/%.cpp,$(OBJDIR)/bintest/%.o,$(shell find src/ -name '*.cpp'))  $(OBJDIR)/vinfo.o
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
# add cppunit import makefile
# include $(patsubst %,$(EXTLIBDIR)/%/import.mk,$(CPPUNIT))

TLDLIBP=$(LDLIBP):$(subst $(_space_),:,$(patsubst -L%,%,$(filter -L%,$(TLDFLAGS))))

-include $(patsubst %.o,%.o.d,$(TCPPOBJS))
# ---------------------------------------------------------------------
# transformation rules specific to tests.
# test cpp files compilation
$(OBJDIR)/test/%.o: test/%.cpp
	@$(ABS_PRINT_info) "Compiling test $< ..."
	@mkdir -p $(@D)
	@echo `$(TRACE_DATE_CMD)`"> $(CPPC) $(CXXFLAGS) $(CFLAGS) $(TCFLAGS) -c $< -o $@" >> $(BUILDLOG)
	@grep -v "#\s*include" $< | cpp -E | grep -E "ABS_TEST_.*_BEGIN|ABS_TEST_SUITE_END" | cpp -include $(ABSROOT)/core/include/abs/testdef2cppunitdecl.h | sed -e '/^#/d;s/!$$//g;s/ !!!/\n!!!/g;s/!!!/#/g' > $(patsubst %.o,%.h,$@)
	@$(CPPC) $(CXXFLAGS) $(CFLAGS) $(TCFLAGS) -include $(patsubst %.o,%.h,$@) -MMD -MF $@.d -c $< -o $@ \
	&& ( cp $@.d $@.d.tmp ; sed -e 's/#.*//' -e 's/^[^:]*: *//' -e 's/ *\\$$//' -e '/^$$/ d' -e 's/$$/ :/' $@.d.tmp >> $@.d ; rm $@.d.tmp ) \
	|| ( $(ABS_PRINT_error) "Failed: CFLAGS=$(CXXFLAGS) $(CFLAGS) $(TCFLAGS)" ; exit 1 )

$(OBJDIR)/test/%.o: test/%.c
	@$(ABS_PRINT_info) "Compiling test $< ..."
	@mkdir -p $(@D)
	@echo `$(TRACE_DATE_CMD)`"> $(CC) $(CFLAGS) $(TCFLAGS) -c $< -o $@" >> $(BUILDLOG)
	@$(CC) $(CFLAGS) $(TCFLAGS) -MMD -MF $@.d -c $< -o $@ \
	&& ( cp $@.d $@.d.tmp ; sed -e 's/#.*//' -e 's/^[^:]*: *//' -e 's/ *\\$$//' -e '/^$$/ d' -e 's/$$/ :/' $@.d.tmp >> $@.d ; rm $@.d.tmp ) \
	|| ( $(ABS_PRINT_error) "Failed: CFLAGS=$(CFLAGS) $(TCFLAGS)" ; exit 1 )

$(OBJDIR)/bintest/%.o: $(OBJDIR)/%.o
	@$(ABS_PRINT_info) "Checking $(@F) symbols for Test Mode..."
	@mkdir -p $(@D)
	@echo `$(TRACE_DATE_CMD)`"> objcopy --redefine-sym main=__Exec_Main_Stubbed_for_unit_tests__ $< $@" >> $(BUILDLOG)
	@objcopy --redefine-sym main=__Exec_Main_Stubbed_for_unit_tests__ $< $@

ifneq ($(filter exe library,$(MODTYPE)),)
TTARGETFILEDEP:=$(TARGETFILE)
endif

ifneq ($(ISWINDOWS),true)
define ld-test
@$(ABS_PRINT_info) "Linking $@ ..."
@$(LD) -o $@ $(TCPPOBJS) $(LDFLAGS) $(TLDFLAGS)
endef
else
define ld-test
@$(ABS_PRINT_info) "Linking $(TCYGTARGET) ..."
@$(LD) -shared -o $(TCYGTARGET) -Wl,--out-implib=$@\
	-Wl,--export-all-symbols -Wl,--enable-auto-import -Wl,--whole-archive $(TCPPOBJS) -Wl,--no-whole-archive $(LDFLAGS) $(TLDFLAGS)
endef
endif

# link test target from test objects.
$(TTARGETFILE): $(TCPPOBJS) $(TTARGETFILEDEP)
	@mkdir -p $(@D)
	@$(ld-test)

# ---------------------------------------------------------------------
# Extra dependencies
# ---------------------------------------------------------------------
# Generating test object need cppunit libs and tools to be availables
$(TCPPOBJS): $(patsubst %,$(EXTLIBDIR)/%/import.mk,$(CPPUNIT)) 

ifneq ($(TSRCFILES),)
#dependencies management
$(TSRCFILES):
endif

ifneq ($(wildcard test/Main.cpp),)

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
@( [ -d test ] && mkdir -p $(TTARGETDIR) ) || true 
@( [ -d test ] && rm -f $(TEST_REPORT_PATH) ) || true
endef

ifneq ($(ISWINDOWS),true)
define exec-test
@$(RUNTIME_PROLOG)
( [ -d test ] && PATH="$(RUNPATH)" LD_LIBRARY_PATH="$(TLDLIBP)" TRDIR="$(TRDIR)" TTARGETDIR="$(TTARGETDIR)" LD_PRELOAD="$(TLDPRELOADFORMATTED)" $(RUNTIME_ENV) $1 $(patsubst %,$(EXTLIBDIR)/%/bin/$(TESTRUNNER),$(CPPUNIT)) -x $(TEST_REPORT_PATH) $(TTARGETFILE) $(RUNARGS) $(patsubst %,+f %,$(T)) $(TARGS) 2>&1 | tee $(TTARGETDIR)/$(APPNAME)_$(MODNAME).stdout ) || :
@$(RUNTIME_EPILOG)
endef
else
define exec-test
@( [ -d test ] && PATH="$(RUNPATH):$(TLDLIBP)" LD_LIBRARY_PATH="$(TLDLIBP)" TRDIR="$(TRDIR)" TTARGETDIR="$(TTARGETDIR)" LD_PRELOAD="$(TLDPRELOADFORMATTED)" $(RUNTIME_ENV) $1 $(patsubst %,$(EXTLIBDIR)/%/bin/$(TESTRUNNER),$(CPPUNIT)) -x $(TEST_REPORT_PATH) $(TCYGTARGET) $(RUNARGS) $(patsubst %,+f %,$(T)) $(TARGS) 2>&1 | tee $(TTARGETDIR)/$(APPNAME)_$(MODNAME).stdout ) || true
endef
endif

define post-test
@( [ -d test -a ! -r $(TEST_REPORT_PATH) ] && $(ABS_PRINT_error) "no test report, test runner exited abnormally." ) || true 
@( [ -d test -a -r $(TEST_REPORT_PATH) ] && xsltproc $(ABSROOT)/core/$(TXTXSL) $(TEST_REPORT_PATH) ) || true
@if [ -d test ]; then [ -s $(TEST_REPORT_PATH) ]; else true; fi
endef

define run-test 
$(pre-test)
$(exec-test)
$(post-test)
endef

##  - test: alias for check
test:: testbuild
	$(call run-test, $(TIMEOUTCMD))

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
.PHONY: debugcheck
debugcheck: testbuild
	@printf "define runtests\nrun $(TTARGETFILE) $(RUNARGS) $(patsubst %,+f %,$(T)) $(TARGS)\nend\n" > cmd.gdb
	@printf "\e[1;4mUse runtests command to launch tests from gdb\n\e[37;37;0m"
	@PATH="$(RUNPATH)" LD_LIBRARY_PATH="$(TLDLIBP)" TRDIR="$(TRDIR)" TTARGETDIR="$(TTARGETDIR)" gdb  $(patsubst %,$(EXTLIBDIR)/%/bin/$(TESTRUNNER),$(CPPUNIT)) -x cmd.gdb
	@rm cmd.gdb

GDBSERVER_PORT?=9091
##  - remotedebugtest [RUNARGS="<arg> [<arg>]*": run test from gdbserver debugger] [GDBSERVER_PORT=9091 : default gdbserver port]
.PHONY: remotedebugtest
remotedebugtest: testbuild
	@PATH="$(RUNPATH)" LD_LIBRARY_PATH="$(TLDLIBP)" TRDIR="$(TRDIR)" TTARGETDIR="$(TTARGETDIR)" gdbserver :$(GDBSERVER_PORT) $(patsubst %,$(EXTLIBDIR)/%/bin/$(TESTRUNNER),$(CPPUNIT)) $(TTARGETFILE) $(RUNARGS) $(patsubst %,+f %,$(T)) $(TARGS)

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
	@echo "$(patsubst $(PRJROOT)/%,%,$(patsubst %,$(EXTLIBDIR)/%/bin/$(TESTRUNNER),$(CPPUNIT)))"
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
TESTNAME=$(word 2,$(MAKECMDGOALS))$(T)

.PHONY: newtest
newtest:
	@$(ABS_PRINT_info) "generating test class test/Test$(TESTNAME).cpp to test $(TESTNAME) class."
	@mkdir -p test
	@test -f test/Main.cpp || printf "#include <cppunit/plugin/TestPlugIn.h>\n#undef main\n\
CPPUNIT_PLUGIN_IMPLEMENT();\n" > test/Main.cpp
	@test -f test/Test$(TESTNAME).cpp || printf "/*\n\
 * @file Test$(TESTNAME).cpp\n\
 *\n\
 * Copyright %d $(COMPANY). All rights reserved.\n\
 * Use is subject to license terms.\n\
 *\n\
 * \$$Id$$\n\
 * \$$Date$$\n\
 */\n\
#include \"abs/test.h\"\n\
#include \"$(TINC_PATH)/$(TESTNAME).hpp\"\n\
\n\
namespace test {\n\
using namespace $(TNAMESPACE);\n\
\n\
// ----------------------------------------------------------\n\
// test suite implementation\n\
ABS_TEST_SUITE_BEGIN( Test$(TESTNAME) )\n\
// uncomment and cmplete next line for test suite description\n\
// ABS_TEST_DESCR(test description)\n\
\n\
private:\n\
\n\
public:\n\
    void setUp() {\n\
    }\n\
\n\
    void tearDown() {\n\
    }\n\
\n\
/* Test case template, uncomment and complete according this pattern for each test case\n\
    ABS_TEST_CASE_BEGIN(NameOfTestCase)\n\
        ABS_TEST_DESCR(Test case description)\n\
        ABS_TEST_CASE_REQ(req.id) // one entry for eache requrement checked by this case\n\
        // init/call service / function to be tested and collect results\n\
\n\
        // check results with cppunit asserts\n\
        CPPUNIT_ASSERT( bool expr);\n\
        CPPUNIT_ASSERT_EQUAL(expected_value,computed_value);\n\
    ABS_TEST_CASE_END\n\
*/\n\
ABS_TEST_SUITE_END\n\
} // namespace test\n" `date +%Y` > test/Test$(TESTNAME).cpp

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
