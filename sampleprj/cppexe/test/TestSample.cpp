#include <cppunit/extensions/HelperMacros.h>

namespace test {

// ----------------------------------------------------------
// test fixture implementation
class TestSample: public CppUnit::TestFixture {
CPPUNIT_TEST_SUITE( TestSample );
CPPUNIT_TEST( testSample1 );
CPPUNIT_TEST( testSample2 );
CPPUNIT_TEST_SUITE_END();

private:

public:
    void setUp() {
    }

    void tearDown() {
    }

    void testSample1() {
    }

    void testSample2() {
    }

};

CPPUNIT_TEST_SUITE_REGISTRATION(TestSample);
} // namespace test
