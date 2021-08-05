#include "BuildScriptTester/cpplib/Example.hpp"
#include <stdio.h>
#include <string.h>
#include "sampleprj/cpplib/res.h"
#include "abs/profiler.h"

#define STR_VALUE(name) #name
#define MACRO_STRVALUE(name) STR_VALUE(name)
namespace BuildScriptTester {
	namespace cpplib {
// --------------------------------------------------------------------
// ..........................................................
//
void Example::helloWorld() {
    PROFILER_FUNCTION_COL(Blue);
    char str[1024];
	printf("Hello world from " MACRO_STRVALUE(__APPNAME__) "::" MACRO_STRVALUE(__MODNAME__) "!\n" );
    printf("len=%d\n",sampleprj_cpplib_res_text_dat_len);
    printf("bufptr=%x\n",sampleprj_cpplib_res_text_dat);
    strncpy(str,(const char *)sampleprj_cpplib_res_text_dat,sampleprj_cpplib_res_text_dat_len);
    str[sampleprj_cpplib_res_text_dat_len]='\0';
	printf("[%s]\n",sampleprj_cpplib_res_text_dat);
}

}} // namespace BuildScriptTester::cpplib 
