#ifndef __ABS_TEST_H__
#define __ABS_TEST_H__
#include <iostream>
#include <cppunit/extensions/HelperMacros.h>
#include <cppunit/plugin/TestPlugIn.h>

#define ABS_TEST_CASE_BEGIN(testCaseName) \
   void test##testCaseName () { \
        const char* _abs_test_case_name = #testCaseName; \
        std::cout << std::endl << "ABS_TEST_CASE_START(" \
            << _abs_test_case_name << ")" << std::endl;

#define ABS_TEST_CASE_END \
        std::cout << "ABS_TEST_CASE_COMPLETED(" << _abs_test_case_name << ")" << std::endl; \
    }

#define ABS_TEST_CASE_REQ(req) \
        std::cout << "ABS_TEST_CASE_REQ(" << _abs_test_case_name << "," \
            << #req << ")" << std::endl;

#endif // __ABS_TEST_H__
