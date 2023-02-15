/*
 * @file TestDependencies.cpp
 *
 * Copyright 2023 eduvax. All rights reserved.
 * Use is subject to license terms.
 *
 * $Id$
 * $Date$
 */
#include "abs/test.h"

#include <cstdlib>

namespace test {

// ----------------------------------------------------------
// test suite implementation
ABS_TEST_SUITE_BEGIN( TestDependencies )
// uncomment and cmplete next line for test suite description
// ABS_TEST_DESCR(test description)

private:

public:
    void setUp() {
    }

    void tearDown() {
    }

    ABS_TEST_CASE_BEGIN(Dependencies)
        CPPUNIT_ASSERT_EQUAL(0, ::system("./test/scripts/testDependencies.sh"));
    ABS_TEST_CASE_END

/* Test case template, uncomment and complete according this pattern for each test case
    //ABS_TEST_CASE_BEGIN(NameOfTestCase)
        ABS_TEST_DESCR(Test case description)
        ABS_TEST_CASE_REQ(req.id) // one entry for eache requrement checked by this case
        // init/call service / function to be tested and collect results

        // check results with cppunit asserts
        CPPUNIT_ASSERT( bool expr);
        CPPUNIT_ASSERT_EQUAL(expected_value,computed_value);
    ABS_TEST_CASE_END
*/
ABS_TEST_SUITE_END
} // namespace test
