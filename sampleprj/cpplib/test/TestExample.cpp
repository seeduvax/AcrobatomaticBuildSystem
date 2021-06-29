#include <cppunit/extensions/HelperMacros.h>
#include <cppunit/plugin/TestPlugIn.h>
#include "BuildScriptTester/cpplib/Example.hpp"
#include "abs/profiler.h"

using namespace BuildScriptTester::cpplib;

namespace test {
#define STR_VALUE(name) #name
#define MACRO_STRVALUE(name) STR_VALUE(name)


// ----------------------------------------------------------
// test fixture implementation
class TestExample: public CppUnit::TestFixture {
CPPUNIT_TEST_SUITE( TestExample );
CPPUNIT_TEST( testCaseSuccess );
CPPUNIT_CONDITIONAL_TEST( IS_INTERACTIVE , testCaseFail );
CPPUNIT_TEST_SUITE_END();

private:

public:
    void setUp() {
        PROFILER_FRAME("TestExample")
        PROFILER_FUNCTION;
    }

    void tearDown() {
        PROFILER_FUNCTION;
    }

    void testCaseSuccess() {
        PROFILER_FUNCTION;
        PROFILER_PLOT("test",0.0);
        Example ex;
        ex.helloWorld();
        std::cout << "in test case of " 
            << MACRO_STRVALUE(__APPNAME__) << "::" 
            << MACRO_STRVALUE(__MODNAME__) << std::endl;
        CPPUNIT_ASSERT_EQUAL(1,1);
        PROFILER_PLOT("test",1.0);
    }

    void testCaseFail() {
        PROFILER_FUNCTION;
        CPPUNIT_ASSERT_EQUAL(0,1);
    }
};

CPPUNIT_TEST_SUITE_REGISTRATION(TestExample);
} // namespace test

