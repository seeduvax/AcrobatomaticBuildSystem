## 
## ---------------------------------------------------------------------
## JUnit services
## 
## Java test services variables:
## 
##  - JUNIT: junit package name (default is junit-4.8.2)
JUNIT?=junit-4.8.2
JUNITXML?=junitXmlFormatter-0.0
TXTXSL=xunit2txt.xsl
TESTCLASSFILES=$(patsubst %.java,$(OBJDIR)/%.class,$(shell find test -name "Test*.java" 2>/dev/null))
ifeq ($(ISWINDOWS),true)
TESTCLASSPATH=$(shell cygpath -mp '$(OBJDIR):$(JARIMGDIR):$(NA_EXTLIBDIR)/$(JUNIT).jar:$(NA_EXTLIBDIR)/$(JUNITXML).jar');$(CLASSPATH)
JUFLAGS=-classpath "$(TESTCLASSPATH)" -d "$(shell cygpath -m '$(OBJDIR)')" -sourcepath "$(shell cygpath -mp '.:src:$(OBJDIR)')"
else
TESTCLASSPATH=$(OBJDIR):$(JARIMGDIR):$(NA_EXTLIBDIR)/$(JUNIT).jar:$(NA_EXTLIBDIR)/$(JUNITXML).jar:$(CLASSPATH)
JUFLAGS=-classpath "$(TESTCLASSPATH)" -d $(OBJDIR) -sourcepath ".:src:$(OBJDIR)"
endif

TTARGETDIR=$(TRDIR)/test
$(OBJDIR)/test/%.class: test/%.java
	@$(ABS_PRINT_info) "Compiling test class $< ..."
	@mkdir -p $(OBJDIR)
	@echo `date --rfc-3339 s`'> $(JC) $(JUFLAGS) $<' >> $(TRDIR)/build.log
	@$(JC) $(JUFLAGS) $< || ( echo 'Failed: JUFLAGS=$(JUFLAGS)' ; exit 1 )

$(OBJDIR)/test/%.class: src/test/%.java
	@$(ABS_PRINT_info) "Compiling test class $< ..."
	@mkdir -p $(OBJDIR)
	@echo `date --rfc-3339 s`'> $(JC) $(JUFLAGS) $<' >> $(TRDIR)/build.log
	@$(JC) $(JUFLAGS) $< || ( echo 'Failed: JUFLAGS=$(JUFLAGS)' ; exit 1 )

$(TESTCLASSFILES): $(NA_EXTLIBDIR)/$(JUNITXML).jar $(NA_EXTLIBDIR)/$(JUNIT).jar $(TARGETFILE)

## 
## Targets:
## 
##  - check: run all tests
##  - test: run all tests
ifeq ($(wildcard test),)
test:: $(TARGETFILE)
else
test:: $(TESTCLASSFILES)
	@$(ABS_PRINT_info) "check : running tests $(TESTCLASSFILES)"
	@mkdir -p $(TTARGETDIR)
	@rm -f $(TTARGETDIR)/$(APPNAME)_$(MODNAME).xml
ifeq ($(ISWINDOWS),true)
	TRDIR="$(shell cygpath -m '$(TRDIR)')" TTARGETDIR="$(shell cygpath -m '$(TTARGETDIR)')" $(JAVA) -cp "$(TESTCLASSPATH)"\
     -Dorg.schmant.task.junit4.target="$(shell cygpath -m '$(TTARGETDIR)/$(APPNAME)_$(MODNAME).xml')" $(TOPTS)\
     barrypitman.junitXmlFormatter.Runner $(subst /,.,$(patsubst $(OBJDIR)/test/%.class,test/%,$(TESTCLASSFILES)))\
     2>&1 | tee $(TTARGETDIR)/$(APPNAME)_$(MODNAME).stdout  || true
else
	@TRDIR="$(TRDIR)" TTARGETDIR="$(TTARGETDIR)" $(JAVA) -cp "$(TESTCLASSPATH)"\
     -Dorg.schmant.task.junit4.target=$(TTARGETDIR)/$(APPNAME)_$(MODNAME).xml $(TOPTS)\
     barrypitman.junitXmlFormatter.Runner $(subst /,.,$(patsubst $(OBJDIR)/test/%.class,test/%,$(TESTCLASSFILES)))\
     2>&1 | tee $(TTARGETDIR)/$(APPNAME)_$(MODNAME).stdout  || true
endif
	@if [ ! -r $(TTARGETDIR)/$(APPNAME)_$(MODNAME).xml ]; then $(ABS_PRINT_error) "no test report, test runner exited abnormally."; \
	else xsltproc $(ABSROOT)/core/$(TXTXSL) $(TTARGETDIR)/$(APPNAME)_$(MODNAME).xml; fi
endif

##  - <TestClassName>: run tests define in test class defined in
##    test/<TestClassName>.java
Test%: $(OBJDIR)/test/Test%.class
	@$(ABS_PRINT_info) "Test% : running test $@"
	@$(JAVA) -cp "$(TESTCLASSPATH)" org.junit.runner.JUnitCore test.$@


##  - newtest <name of class to be tested>: create a new test source file in
##      the test directory.
ifeq ($(word 1,$(MAKECMDGOALS)),newtest)
TESTNAME=$(word 2,$(MAKECMDGOALS))$(T)
.PHONY: newtest
newtest:
	@$(ABS_PRINT_info) "generating Junit test class test/Test$(TESTNAME).java to test $(TESTNAME) class."
	@mkdir -p test
	@test -f test/Test$(TESTNAME).java || printf "package test;\n\
import org.junit.*;\n\
import static org.junit.Assert.*;\n\
import $(DOMAIN).$(APPNAME).$(MODNAME).$(TESTNAME);\n\
\n\
/**\n\
 *\n\
 */\n\
public class Test$(TESTNAME) {\n\
    /**\n\
     * Pre-test initialisations.\n\
     */\n\
    @Before public void setUp() {\n\
    }\n\
    /**\n\
     * Post-test finalizations.\n\
     */\n\
    @After public void tearDown() {\n\
    }\n\
\n\
    /**\n\
     *\n\
     */\n\
    @Test public void test() {\n\
    }\n\
}\n\
" > test/Test$(TESTNAME).java

$(TESTNAME):
	@:


endif
