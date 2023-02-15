#include "projA/cpplib/Example.hpp"
#include <stdio.h>
#include <string.h>
#include "projA/cpplib/res.h"
#include "abs/profiler.h"

#define STR_VALUE(name) #name
#define MACRO_STRVALUE(name) STR_VALUE(name)
namespace projA {
	namespace cpplib {
// --------------------------------------------------------------------
// ..........................................................
//
void Example::helloWorld() {
    PROFILER_FUNCTION_COL(Blue);
    char str[1024];
	printf("Hello world from " MACRO_STRVALUE(__APPNAME__) "::" MACRO_STRVALUE(__MODNAME__) "!\n" );
    printf("len=%d\n",projA_cpplib_res_text_dat_len);
    printf("bufptr=%x\n",projA_cpplib_res_text_dat);
    strncpy(str,(const char *)projA_cpplib_res_text_dat,projA_cpplib_res_text_dat_len);
    str[projA_cpplib_res_text_dat_len]='\0';
	printf("[%s]\n",projA_cpplib_res_text_dat);
}

}} // namespace projA::cpplib 
