##
## CPPUNIT configuration variables
##
##  - CPPUNIT: cppunit version. Default is set accorging your gcc version
##    - 1.14.0 for gcc >= 6.0
##    - 1.12.1 for gcc < 6.0
ifeq ($(filter %-win32 %-posix,$(CC_VERSION)),)
CC_VERSION_GE6:=$(shell [ `echo "$(CC_VERSION)" | cut -f1 -d.` -ge 6 ] && echo true || echo false)
ifeq ($(CC_VERSION_GE6),false)
CPPUNIT?=cppunit|1.12.1
endif
endif
CPPUNIT?=cppunit|1.14.0

TESTRUNNER=ctrunner$(BINEXT)
TXTXSL=xunit2txt.xsl
# default TIMEOUT 10min
TIMEOUT?=600
ifeq ($(COLORS_TCAP),yes)
TIMEOUTCMD:=
else
TIMEOUTCMD:=timeout $(TIMEOUT)
endif

CPPUNIT_DIR=$(call GetExtLibDir,$(NDEXTLIBDIR),$(CPPUNIT))
TCFLAGS+=-I$(CPPUNIT_DIR)/include
TLDFLAGS+=-L$(CPPUNIT_DIR)/$(SODIR)
TLINKLIB+=cppunit

define pre_compile_cpp_test
# generation of header for cppunit tests definition. Remove one line defines to avoid resolving them now.
	@grep -v "#\s*include" $< | grep -v -E "#\s*define.*[^\]$$" | $(CPPC) -x c++ -E - |\
		grep -E "ABS_TEST_.*_BEGIN|ABS_TEST_SUITE_END" | sed -E 's/\{ *$$//g' |\
		$(CPPC) -x c++ -E -include $(ABSROOT)/core/include/abs/testdef2cppunitdecl.h - |\
		sed -e '/^#/d;s/!$$//g;s/ !!!/\n!!!/g;s/!!!/#/g' > $(patsubst %.o,%.h,$@)
	$(gen-json-test-cppc)
endef

define pre_compile_c_test
	$(gen-json-test-cc)
endef

define updateOptionsAndFlags 
  $(eval $(1):= -shared -include $(patsubst %.o,%.h,$(4)) $(2) $(3))
endef

ARE_TESTS_AVAILABLE:=$(wildcard test/Main.cpp)

define post-test
@( [ -d test -a ! -r $(TEST_REPORT_PATH) ] && $(ABS_PRINT_error) "no test report, test runner exited abnormally." ) || true 
@( [ -d test -a -r $(TEST_REPORT_PATH) ] && xsltproc $(ABSROOT)/core/$(TXTXSL) $(TEST_REPORT_PATH) ) || true
@if [ -d test ]; then [ -s $(TEST_REPORT_PATH) ]; else true; fi
endef


CPP_UNIT_TESTER_LIB:=$(CPPUNIT)

TEST_RUNNER_CMD:=$(CPPUNIT_DIR)/bin/$(TESTRUNNER)
TEST_RUNNER_ARG_XML:=-x 

define new_test_cmd
	@$(ABS_PRINT_info) "Generating test class test/Test$(TESTNAME).cpp to test $(TESTNAME) class."
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
ABS_TEST_SUITE_BEGIN( $(TESTNAME) )\n\
// uncomment and complete next line for test suite description\n\
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
    ABS_TEST_CASE_BEGIN(NameOfTestCase) {\n\
        ABS_TEST_DESCR(Test case description)\n\
        ABS_TEST_CASE_REQ(req.id) // one entry for each requirement checked by this case\n\
        // init/call service / function to be tested and collect results\n\
\n\
        // check results with cppunit asserts\n\
        CPPUNIT_ASSERT( bool expr);\n\
        CPPUNIT_ASSERT_EQUAL(expected_value,computed_value);\n\
    }\n\
    ABS_TEST_CASE_END\n\
*/\n\
ABS_TEST_SUITE_END\n\
} // namespace test\n" `date +%Y` > test/Test$(TESTNAME).cpp

endef
