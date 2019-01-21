## 
## --------------------------------------------------------------------
## C/C++ Unit test services
## 
## Test services variables
## 
##  - CPPUNIT: cppunit version (default is cppunit-1.12.1)
CPPUNIT?=cppunit-1.14.0
TESTRUNNER=ctrunner
TXTXSL=xunit2txt.xsl
TIMEOUT=300
ifeq ($(COLORS_TCAP),yes)
TIMEOUTCMD:=
else
TIMEOUTCMD:=timeout $(TIMEOUT)
endif

CFLAGS+=-I$(EXTLIBDIR)/$(CPPUNIT)/include
LDFLAGS+=-L$(EXTLIBDIR)/$(CPPUNIT)/$(SODIR)

# valgrind
VALGRIND=valgrind

# relpath tool
RELPATH=$(ABSROOT)/core/relpath.sh

# Target definition.
TTARGETDIR=$(TRDIR)/test
TTARGETFILE=$(TTARGETDIR)/t_$(TARGET)

ifeq ($(VALGRIND_XML),true)
	VALGRIND_ARGS+=--xml=yes --xml-file=$(TTARGETDIR)/$(MODNAME)_valgrind_result.xml
endif

# objects to be generated from test classes.
TSRCFILES=$(shell find test/ -name '*.cpp' 2>/dev/null)
TCPPOBJS=$(patsubst test/%.cpp,$(OBJDIR)/test/%.o,$(TSRCFILES)) 

# compiler options specific to test
TCFLAGS+=

# linker options specific to test
TLDFLAGS+= -L$(TRDIR)/$(SODIR) $(patsubst %,-l$(APPNAME)_%,$(TESTUSEMOD)) -lcppunit

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
	TCFLAGS+=-D'main(a,b)=__Exec_Main_Stubbed_for_unit_tests_(a,b)'
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

TLDLIBP=$(LDLIBP):$(subst !!,,$(subst !! ,:,$(patsubst -%,,$(patsubst -L%,%!!,$(TLDFLAGS)))))

-include $(patsubst %.o,%.o.d,$(TCPPOBJS))
# ---------------------------------------------------------------------
# transformation rules specific to tests.
# test cpp files compilation
$(OBJDIR)/test/%.o: test/%.cpp 
	@$(ABS_PRINT_info) "Compiling test $< ..."
	@mkdir -p $(@D)
	@echo `date --rfc-3339 s`"> $(CPPC) $(CFLAGS) $(TCFLAGS) -c $< -o $@" >> $(TRDIR)/build.log
	@$(CPPC) $(CFLAGS) $(TCFLAGS) -MMD -MF $@.d -c $< -o $@ \
	&& ( cp $@.d $@.d.tmp ; sed -e 's/#.*//' -e 's/^[^:]*: *//' -e 's/ *\\$$//' -e '/^$$/ d' -e 's/$$/ :/' $@.d.tmp >> $@.d ; rm $@.d.tmp ) \
	|| ( $(ABS_PRINT_error) "Failed: CFLAGS=$(CFLAGS) $(TCFLAGS)" ; exit 1 )

$(OBJDIR)/bintest/%.o: src/%.c 
	@$(ABS_PRINT_info) "Compiling $< [Test Mode] ..."
	@mkdir -p $(@D)
	@echo `date --rfc-3339 s`"> $(CC) $(CFLAGS) $(TCFLAGS) -c $< -o $@" >> $(TRDIR)/build.log
	@$(CC) $(CFLAGS) $(TCFLAGS) -MMD -MF $@.d -c $< -o $@ \
	&& ( cp $@.d $@.d.tmp ; sed -e 's/#.*//' -e 's/^[^:]*: *//' -e 's/ *\\$$//' -e '/^$$/ d' -e 's/$$/ :/' $@.d.tmp >> $@.d ; rm $@.d.tmp ) \
	|| ( $(ABS_PRINT_error) "Failed: CFLAGS=$(CFLAGS) $(TCFLAGS)" ; exit 1 )

$(OBJDIR)/bintest/%.o: src/%.cpp 
	@$(ABS_PRINT_info) "Compiling $< [Test Mode] ..."
	@mkdir -p $(@D)
	@echo `date --rfc-3339 s`"> $(CPPC) $(CFLAGS) $(TCFLAGS) -c $< -o $@" >> $(TRDIR)/build.log
	@$(CPPC) $(CFLAGS) $(TCFLAGS) -MMD -MF $@.d -c $< -o $@ \
	&& ( cp $@.d $@.d.tmp ; sed -e 's/#.*//' -e 's/^[^:]*: *//' -e 's/ *\\$$//' -e '/^$$/ d' -e 's/$$/ :/' $@.d.tmp >> $@.d ; rm $@.d.tmp ) \
	|| ( $(ABS_PRINT_error) "Failed: CFLAGS=$(CFLAGS) $(TCFLAGS)" ; exit 1 )

ifneq ($(filter exe library,$(MODTYPE)),)
TTARGETFILEDEP:=$(TARGETFILE)
endif

# link test target from test objects.
$(TTARGETFILE): $(TCPPOBJS) $(TTARGETFILEDEP)
	@mkdir -p $(TTARGETDIR)
	@$(ABS_PRINT_info) "Linking $@ ..."
	@$(LD) -o $@ $(TCPPOBJS) $(LDFLAGS) $(TLDFLAGS)

# ---------------------------------------------------------------------
# Extra dependencies
# ---------------------------------------------------------------------
# Generating test object need cppunit libs and tools to be availables
$(TCPPOBJS): $(MODDEPS) $(patsubst %,$(EXTLIBDIR)/%/import.mk,$(CPPUNIT)) 

ifneq ($(TSRCFILES),)
#dependencies management
$(TSRCFILES): $(MODDEPS)
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
	@/bin/bash -c "echo \"Filtering $@ ...\"; $(filterCmds)" 
	
# ---------------------------------------------------------------------
## 
## Test targets:
## 
##  - testbuild: builds tests but do not run them.
.PHONY:	testbuild
testbuild::	$(TTARGETFILE) $(FILTERED_TEST_FILES_OUTPUT)

define run-test 
@( [ -d test ] && mkdir -p $(TTARGETDIR) ) || true 
@( [ -d test ] && rm -f $(TTARGETDIR)/$(APPNAME)_$(MODNAME).xml ) || true 
@( [ -d test ] && LD_LIBRARY_PATH=$(TLDLIBP) TRDIR=$(TRDIR) TTARGETDIR=$(TTARGETDIR) $1 $(patsubst %,$(EXTLIBDIR)/%/bin/$(TESTRUNNER),$(CPPUNIT)) -x $(TTARGETDIR)/$(APPNAME)_$(MODNAME).xml $(TTARGETFILE) $(RUNARGS) $(patsubst %,+f %,$(T)) $(TARGS) 2>&1 | tee $(TTARGETDIR)/$(APPNAME)_$(MODNAME).stdout ) || true
@( [ -d test -a ! -r $(TTARGETDIR)/$(APPNAME)_$(MODNAME).xml ] && $(ABS_PRINT_error) "no test report, test runner exited abnormally." ) || true 
@( [ -d test -a -r $(TTARGETDIR)/$(APPNAME)_$(MODNAME).xml ] && xsltproc $(ABSROOT)/core/$(TXTXSL) $(TTARGETDIR)/$(APPNAME)_$(MODNAME).xml ) || true
@if [ -d test ]; then [ -s $(TTARGETDIR)/$(APPNAME)_$(MODNAME).xml ]; else true; fi
endef
	
##  - test: alias for check
test:: testbuild
	$(call run-test, $(TIMEOUTCMD))

##  - check [RUNARGS="<arg> [<arg>]*] [T=<test name>]: builds and runs tests
##         When only one test shall be run, use optionnal T variable argument.
check:: test

##  - valgrindtest: run tests from valgrind for profiling.
.PHONY: valgrindtest
valgrindtest:: testbuild
	$(call run-test, $(VALGRIND) $(VALGRIND_ARGS))

##  - debugcheck [RUNARGS="<arg> [<arg>]*": run test from gdb debugger
.PHONY: debugcheck
debugcheck: testbuild
	@printf "define runtests\nrun $(TTARGETFILE) $(RUNARGS) $(patsubst %,+f %,$(T)) $(TARGS)\nend\n" > cmd.gdb
	@printf "\e[1;4mUse runtests command to launch tests from gdb\n\e[37;37;0m"
	@LD_LIBRARY_PATH=$(TLDLIBP) TRDIR=$(TRDIR) TTARGETDIR=$(TTARGETDIR) gdb  $(patsubst %,$(EXTLIBDIR)/%/bin/$(TESTRUNNER),$(CPPUNIT)) -x cmd.gdb
	@rm cmd.gdb

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

##  - edebugtest: print unit tests setup for eclipse
.PHONY:	edebugtest
edebugtest:	
	@echo "**** Eclipse debugger setup for tests : ****"
	@echo
	@printf "Application:\t\t"
	@echo "$(patsubst %,$(EXTLIBDIR)/%/bin/$(TESTRUNNER),$(CPPUNIT))" | $(RELPATH) $(PRJROOT)
	@printf "Arguments:\t\t"
	@file=$$(echo "$(TTARGETFILE)" | $(RELPATH)) ; printf "$$file "
	@echo "$(RUNARGS)  $(patsubst %,+f %,$(T))"
	@echo
	@echo "* Environment (replace native) :"
	@echo
	@printf "LD_LIBRARY_PATH\t"
	@echo $(TLDLIBP) | $(RELPATH)
	@printf "TRDIR\t\t"
	@echo $(TRDIR) | $(RELPATH)
	@printf "TTARGETDIR\t"
	@echo $(TTARGETDIR) | $(RELPATH)

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
#include <cppunit/extensions/HelperMacros.h>\n\
#include \"$(TINC_PATH)/$(TESTNAME).hpp\"\n\
\n\
namespace test {\n\
using namespace $(TNAMESPACE);\n\
\n\
// ----------------------------------------------------------\n\
// test fixture implementation\n\
class Test$(TESTNAME): public CppUnit::TestFixture {\n\
CPPUNIT_TEST_SUITE( Test$(TESTNAME) );\n\
// TODO for each test method:\n\
// CPPUNIT_TEST( test...);\n\
CPPUNIT_TEST_SUITE_END();\n\
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
};\n\
\n\
CPPUNIT_TEST_SUITE_REGISTRATION(Test$(TESTNAME));\n\
} // namespace test\n" `date +%Y` > test/Test$(TESTNAME).cpp

$(TESTNAME):

endif

clean:: clean-module-test

clean-module-test:
	rm -rf $(TTARGETFILE) $(FILTERED_TEST_FILES_OUTPUT)
	rm -rf $(TTARGETDIR)/$(APPNAME)_$(MODNAME).stdout
	rm -rf $(TTARGETDIR)/$(APPNAME)_$(MODNAME).xml

