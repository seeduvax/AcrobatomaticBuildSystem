/*
 * Use with something like :
grep "ABS_TEST_.*_BEGIN" test/TestExample.cpp | cpp -include ../../core/include/abs/testdef2cppunitdecl.h | grep -v "^# " | sed -e 's/!!!$/\\/g' | sed -e 's/!!!/#/g'
 */ 


#define ABS_TEST_SUITE_BEGIN(testSuiteName)/* how to make a CR here ?
*/\
!!!define __ABS_TEST_SUITE_NAME testSuiteName \
!!!define __ABS_TEST_SUITE_CPPUNIT_DECL !!!
#define ABS_TEST_CASE_BEGIN(testCaseName) CPPUNIT_TEST(test##testCaseName) !!!

