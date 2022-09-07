#include "abs/test.h" 

namespace test {

// ----------------------------------------------------------
// test fixture implementation
ABS_TEST_SUITE_BEGIN(Sample)

private:

public:
    void setUp() {
    }

    void tearDown() {
    }

    ABS_TEST_CASE_BEGIN(Sample1) 
        ABS_TEST_CASE_REQ(req.1)
    ABS_TEST_CASE_END

    ABS_TEST_CASE_BEGIN(Sample2) 
    ABS_TEST_CASE_END
ABS_TEST_SUITE_END
} // namespace test
