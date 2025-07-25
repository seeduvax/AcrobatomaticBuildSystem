## 
## ------------------------------------------------------------------------
## GEODE test library
## ------------------------------------------------------------------------
## 

ifneq ($(XARCH),)
	GEODE_TEST:=tools-1.0ed
	TESTEXTLIBDIR=$(NDXA_EXTLIBDIR)
else
	GEODE_TEST:=tools-1.0ed
	TESTEXTLIBDIR=$(NDEXTLIBDIR)
endif

ifeq ($(WITH_GOOGLE_TEST),true)
        ifneq ($(XARCH),)
                GOOGLE_TEST=googletest-1.10.0
        	TCFLAGS+= -DWITH_GOOGLE_TEST -I$(googletest-1.10.0_INSTALL_DIR)/include
	        TLDFLAGS+= -L$(googletest-1.10.0_INSTALL_DIR)/lib -L$(googletest-1.17.0_INSTALL_DIR)/lib64
        else
                GOOGLE_TEST=googletest-1.17.0
        	TCFLAGS+= -DWITH_GOOGLE_TEST -I$(googletest-1.17.0_INSTALL_DIR)/include
	        TLDFLAGS+= -L$(googletest-1.17.0_INSTALL_DIR)/lib -L$(googletest-1.17.0_INSTALL_DIR)/lib64
                TCXXFLAGS+= --std=c++17
        endif
        TLINKLIB+= gtest gtest_main

        ifneq ($(NO_PTHREAD),true)
                TCFLAGS+= -DGTEST_HAS_PTHREAD=1
                TLINKLIB+= pthread
	else
		TCFLAGS+= -DGTEST_HAS_PTHREAD=0
        endif
endif

TCFLAGS+=-I$(TESTEXTLIBDIR)/$(GEODE_TEST)/include
TLDFLAGS+=-L$(TESTEXTLIBDIR)/$(GEODE_TEST)/$(SODIR) 
TLINKLIB+= tools_testing tools_printf tools_uart 

define pre_compile_cpp_test
	@echo "TLINKLIB = $(TLINKLIB)"
	@echo "TLDFLAGS = $(TLDFLAGS)"
	@echo "TCFLAGS  = $(TCFLAGS)"
	@echo "TCXXFLAGS  = $(TCXXFLAGS)"
endef

define pre_compile_c_test
endef

define updateOptionsAndFlags
 $(eval $(1):= -Wl,--start-group $(filter-out -shared, $(2) $(3)) -Wl,--end-group)
endef

ARE_TESTS_AVAILABLE:=$(if $(strip $(wildcard test/*.c)$(wildcard test/*.cpp),), test_availbale,)

define post-test
endef

TEST_RUNNER_ARG_XML:= 
TEST_RUNNER_CMD=unbuffer

CPP_UNIT_TESTER_LIB:=$(GEODE_TEST) $(GOOGLE_TEST)

define new_test_cmd
	@$(ABS_PRINT_info) "Generating test class test/test_(TESTNAME).cpp to test $(TESTNAME) class."
	@mkdir -p test
	@test -f test/test_(TESTNAME).cpp || printf "|| printf "/*\n\
 * @file Test$(TESTNAME).cpp\n\
 *\n\
 * Copyright %d $(COMPANY). All rights reserved.\n\
 * Use is subject to license terms.\n\
 *\n\
 * \$$Id$$\n\
 * \$$Date$$\n\
 */\n\
 \n\
 // namespace test\n" `date +%Y` > test/test_$(TESTNAME).cpp
endef

