
#define ABS_TEST_SUITE_BEGIN(testSuiteName, ...) \
!!!define __ABS_TEST_SUITE_NAME testSuiteName \
!!!define __ABS_TEST_SUITE_NAME_STR #testSuiteName \
!!!define __ABS_TEST_SUITE_CLASS_NAME Test##testSuiteName \
!!!define __ABS_TEST_SUITE_CPPUNIT_DECL \!
#define ABS_TEST_CASE_BEGIN(testCaseName) CPPUNIT_TEST(test##testCaseName); \!
#define ABS_TEST_CONDITIONAL_CASE_BEGIN(condition,testCaseName) CPPUNIT_CONDITIONAL_TEST(condition,test##testCaseName); \!
#define ABS_TEST_SUITE_END !
