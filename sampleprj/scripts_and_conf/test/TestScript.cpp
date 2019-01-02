#include <cppunit/extensions/HelperMacros.h>
#include <stdlib.h>

namespace test {
// ----------------------------------------------------------
// test fixture implementation
class TestScript: public CppUnit::TestFixture {
CPPUNIT_TEST_SUITE( TestScript );
// TODO for each test method:
CPPUNIT_TEST( testScript );
CPPUNIT_TEST_SUITE_END();

private:

public:
    void setUp() {
    }

    void tearDown() {
    }

    void testScript() {
        std::string tdir(getenv("TRDIR"));
        std::string cmd=tdir+"/bin/sampleprj.sh";
        int res=system(cmd.c_str());
        CPPUNIT_ASSERT_EQUAL(0,res);
    }
};

CPPUNIT_TEST_SUITE_REGISTRATION(TestScript);
} // namespace test
