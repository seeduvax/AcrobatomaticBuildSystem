#ifndef __ABS_TEST_H__
#define __ABS_TEST_H__
#include <iostream>
#include <cppunit/extensions/HelperMacros.h>
#include <cppunit/plugin/TestPlugIn.h>

#define ABS_TEST_SUITE_BEGIN(testSuiteName, ...) class Test##testSuiteName: public CppUnit::TestFixture , ##__VA_ARGS__ {

#define ABS_TEST_SUITE_END CPPUNIT_TEST_SUITE(__ABS_TEST_SUITE_CLASS_NAME); \
__ABS_TEST_SUITE_CPPUNIT_DECL \
CPPUNIT_TEST_SUITE_END(); \
}; \
CPPUNIT_TEST_SUITE_REGISTRATION(__ABS_TEST_SUITE_CLASS_NAME);

#define ABS_TEST_CASE_BEGIN(testCaseName) \
   void test##testCaseName () { \
        const char* _abs_test_case_name = __ABS_TEST_SUITE_NAME_STR "_" #testCaseName; \
        std::cout << std::endl << "ABS_TEST_CASE_START(" \
            << _abs_test_case_name << ")" << std::endl;

#define ABS_TEST_CONDITIONAL_CASE_BEGIN(condition,testCaseName) ABS_TEST_CASE_BEGIN(testCaseName)
#define ABS_TEST_DESCR(...)

#define ABS_TEST_CASE_END \
        std::cout << "ABS_TEST_CASE_COMPLETED(" << _abs_test_case_name << ")" << std::endl; \
    }

#define ABS_TEST_CASE_REQ(req) \
        std::cout << "ABS_TEST_CASE_REQ(" \
            << #req << ")" << std::endl;

#endif // __ABS_TEST_H__
