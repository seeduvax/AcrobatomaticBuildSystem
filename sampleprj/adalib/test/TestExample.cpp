/*
 * @file TestExample.cpp
 *
 * Copyright 2019 eduvax. All rights reserved.
 * Use is subject to license terms.
 *
 * $Id$
 * $Date$
 */
#include <cppunit/extensions/HelperMacros.h>

extern "C" {
    int example__hello(int i);
}

namespace test {

// ----------------------------------------------------------
// test fixture implementation
class TestExample: public CppUnit::TestFixture {
CPPUNIT_TEST_SUITE( TestExample );
CPPUNIT_TEST( testExampleHello );
CPPUNIT_TEST_SUITE_END();

private:

public:
    void setUp() {
    }

    void tearDown() {
    }

    void testExampleHello() {
        int cr=example__hello(42);
        CPPUNIT_ASSERT_EQUAL(43,cr);
    }
};

CPPUNIT_TEST_SUITE_REGISTRATION(TestExample);
} // namespace test
