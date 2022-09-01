/*
 * Caution, this header file is not intended to be included in a C/C++
 * file. 
 * It provides macro definition to ouput HEML data, not C/C++ code.
 */  
#define ABS_TEST_CASE_BEGIN(testCaseName) {testcase %name=testCaseName
#define ABS_TEST_CASE_REQ(reqid) {req reqid}
#define ABS_TEST_CASE_END }
