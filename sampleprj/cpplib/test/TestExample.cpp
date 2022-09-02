#include "abs/test.h"
#include "BuildScriptTester/cpplib/Example.hpp"
#include "abs/profiler.h"

using namespace BuildScriptTester::cpplib;

namespace test {
#define STR_VALUE(name) #name
#define MACRO_STRVALUE(name) STR_VALUE(name)

#ifdef PROFILE_ENABLED
static bool profiler_enabled=true;
#else
static bool profiler_enabled=false;
#endif

class IPlop {
    void toto() {
    }
};
class IPlop2 {
    void toto2() {
    }
};

// ----------------------------------------------------------
// test fixture implementation
ABS_TEST_SUITE_BEGIN(Example, public IPlop, public IPlop2)
public:
    void setUp() {
        PROFILER_FRAME("TestExample")
        PROFILER_FUNCTION_COL(Grey);
    }

    void tearDown() {
        PROFILER_FUNCTION_COL(Grey);
    }

    ABS_TEST_CASE_BEGIN(CaseSuccess)
        ABS_TEST_CASE_REQ(req.1)
        PROFILER_FUNCTION;
        PROFILER_PLOT("testPlot",0.0);
        Example ex;
        ex.helloWorld();
        std::cout << "in test case of " 
            << MACRO_STRVALUE(__APPNAME__) << "::" 
            << MACRO_STRVALUE(__MODNAME__) << std::endl;
        CPPUNIT_ASSERT_EQUAL(1,1);
        PROFILER_PLOT("testPlot",1.0);
    ABS_TEST_CASE_END

    ABS_TEST_CASE_BEGIN(CaseFail) 
        ABS_TEST_CASE_REQ(req.2)
        PROFILER_FUNCTION;
        CPPUNIT_ASSERT_EQUAL(0,1);
    ABS_TEST_CASE_END

    void funcProfA() {
        PROFILER_REGION_BEGIN("ManualScoppedRegion");
    }

    void funcProfB() {
        PROFILER_REGION_END;
    }

    ABS_TEST_CASE_BEGIN(Profiler) 
        ABS_TEST_CASE_REQ(req.3)
        PROFILER_FUNCTION_COL(Red);
        PROFILER_PLOT("testPlot",0.2);
        usleep(50);
        PROFILER_PLOT("testPlot",0.4);
        funcProfA();
        PROFILER_PLOT("testPlot",0.1);
        usleep(100);
        PROFILER_PLOT("testPlot",0.5);
        funcProfB();
        PROFILER_PLOT("testPlot",0.3);
        usleep(50);
        PROFILER_PLOT("testPlot",0.8);
    ABS_TEST_CASE_END

ABS_TEST_SUITE_END
} // namespace test

