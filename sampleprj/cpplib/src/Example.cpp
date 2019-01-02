#include "BuildScriptTester/cpplib/Example.hpp"
#include <stdio.h>
#include <string.h>
#include "sampleprj/cpplib/res.h"

namespace BuildScriptTester {
	namespace cpplib {
// --------------------------------------------------------------------
// ..........................................................
//
void Example::helloWorld() {
    char str[1024];
	printf("Hello world !\n");
    printf("len=%d\n",sampleprj_cpplib_res_text_dat_len);
    printf("bufptr=%x\n",sampleprj_cpplib_res_text_dat);
    strncpy(str,(const char *)sampleprj_cpplib_res_text_dat,sampleprj_cpplib_res_text_dat_len);
    str[sampleprj_cpplib_res_text_dat_len]='\0';
	printf("[%s]\n",sampleprj_cpplib_res_text_dat);




}

}} // namespace BuildScriptTester::cpplib 
