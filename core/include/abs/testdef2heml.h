/*
 * Caution, this header file is not intended to be included in a C/C++
 * file. 
 * It provides macro definition to ouput HEML data, not C/C++ code.
 */  
#define ABS_TEST_SUITE_BEGIN(testSuiteName, ...) {testsuite %name=testSuiteName %src=__TESTFILE__
#define ABS_TEST_SUITE_END }
#define ABS_TEST_CASE_BEGIN(testCaseName) {testcase %name=testCaseName
#define ABS_TEST_CONDITIONAL_CASE_BEGIN(conditionexpr,testCaseName) {testcase %name=testCaseName %condition=conditionexpr
#define ABS_TEST_CASE_START(testCaseName) {testcase %name=testCaseName
#define ABS_TEST_CASE_COMPLETED(testCaseName) {completed}
#define ABS_TEST_CASE_REQ(reqid) {req reqid}
#define ABS_TEST_CASE_END }
#define ABS_TEST_DESCR(...) __VA_ARGS__
