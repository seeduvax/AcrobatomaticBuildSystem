#ifndef __CPPUNIT_ABS_EXTRA__
#define __CPPUNIT_ABS_EXTRA__

#define CPPUNIT_CONDITIONAL_TEST(cond,testMethod) \
if (cond) { \
 CPPUNIT_TEST_SUITE_ADD_TEST(                           \
        ( new CPPUNIT_NS::TestCaller<TestFixtureType>(    \
                  context.getTestNameFor( #testMethod),   \
                  &TestFixtureType::testMethod,           \
                  context.makeFixture() ) ) ); \
} else { \
 CPPUNIT_TEST_SUITE_ADD_TEST(                           \
        ( new CPPUNIT_NS::TestCaller<TestFixtureType>(    \
                  context.getTestNameFor( #testMethod \
                  "__disabled_by_condition__[" #cond "]"),   \
                  &TestFixtureType::testMethod,           \
                  context.makeFixture() ) ) ); \
}

#include <unistd.h>

#define IS_INTERACTIVE isatty(fileno(stdin))
#define FILE_EXISTS(path) (access(path,F_OK)==0)
#define FILE_CANREAD(path) (access(path,R_OK)==0)
#define FILE_CANWRITE(path) (access(path,W_OK)==0)
#define FILE_CANEXEC(path) (access(path,X_OK)==0)

#endif // __CPPUNIT_ABS_EXTRA__
