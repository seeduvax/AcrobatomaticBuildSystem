#include <stdio.h>
extern const char* _sampleprj_vinfo;
extern const char* _sampleprj_version;

int main(int argc,char ** argv) {
    printf("Full version information: %s\nShort version identifier: %s\n",
            _sampleprj_vinfo,
            _sampleprj_version);
	return 0;
}
