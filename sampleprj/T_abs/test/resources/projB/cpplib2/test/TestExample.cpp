#include "abs/test.h"
#include <unistd.h>

#ifndef profiler_enabled
#define profiler_enabled true
#endif

namespace test {
class IPlop {};
class IPlop2 {};

// ----------------------------------------------------------
// test fixture implementation
ABS_TEST_SUITE_BEGIN(Example, public IPlop, public IPlop2)
ABS_TEST_DESCR(Sample test suite. Shows how to implement test case with description and requirement traceability.)
private:
    class Example {
    public:
        void helloWorld(){}
    };

public:
    void setUp() {
    }

    void tearDown() {
    }

    ABS_TEST_CASE_BEGIN(CaseSuccess) {
        ABS_TEST_DESCR(Simple test expected to be successful showing few features.)
        ABS_TEST_CASE_REQ(req.1)
        Example ex;
        ex.helloWorld();
        CPPUNIT_ASSERT_EQUAL(1,1);
    }
    ABS_TEST_CASE_END

    ABS_TEST_CONDITIONAL_CASE_BEGIN(IS_INTERACTIVE, CaseFail) {
        ABS_TEST_DESCR(This test is designed to fail, in order to check the test infrastructure is able to catch a failure.)
        ABS_TEST_CASE_REQ(req.2)
        CPPUNIT_ASSERT_EQUAL(0,1);
    }
    ABS_TEST_CASE_END

    ABS_TEST_CONDITIONAL_CASE_BEGIN(profiler_enabled,Profiler) 
        ABS_TEST_DESCR(Conditional test to be run only when profiler is enabled.)
        ABS_TEST_CASE_REQ(req.3)
        usleep(50);
    ABS_TEST_CASE_END

ABS_TEST_SUITE_END
} // namespace test

