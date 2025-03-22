#define __ABS_TEST_SUITE_NAME Example
#define __ABS_TEST_SUITE_NAME_STR "Example"
#define __ABS_TEST_SUITE_CLASS_NAME TestExample
#define __ABS_TEST_SUITE_CPPUNIT_DECL \
    CPPUNIT_TEST(testCaseSuccess); \
    CPPUNIT_CONDITIONAL_TEST(IS_INTERACTIVE,testCaseFail); \
    CPPUNIT_CONDITIONAL_TEST(false,testProfiler); \

