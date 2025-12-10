## 
## ------------------------------------------------------------------------
## Google test
## ------------------------------------------------------------------------
## 

ifneq ($(XARCH),)
	GOOGLE_TEST:=googletest-1.10.0
	TESTEXTLIBDIR=$(NDXA_EXTLIBDIR)
else
	GOOGLE_TEST?=googletest-1.17.0
	TESTEXTLIBDIR=$(NDEXTLIBDIR)
	TCFLAGS+=--std=c++17 
endif

TEST_SRC_FILE:=test/test_$(TESTNAME).cpp
TEST_SRC_FILES+=$(TEST_SRC_FILE)

TCFLAGS+=-I$(TESTEXTLIBDIR)/$(GOOGLE_TEST)/include
TLDFLAGS+=-L$(TESTEXTLIBDIR)/$(GOOGLE_TEST)/$(SODIR) -L$(TESTEXTLIBDIR)/$(GOOGLE_TEST)/$(SODIR)64
# -L$(TESTEXTLIBDIR)/$(GOOGLE_TEST)/$(SODIR)64 to be confirmed if needed
TLINKLIB+= gtest gtest_main

# on considère qu en croisé on est sans OS sont sans thread. Le mieux serait que l'on recupère les données depuis la lib compilée
ifeq ($(XARCH),)
TCFLAGS+= -DGTEST_HAS_PTHREAD=1
TLINKLIB+= pthread 
else
TCFLAGS+= -DGTEST_HAS_PTHREAD=0
endif

define pre_compile_cpp_test
endef

define pre_compile_c_test
endef

define updateOptionsAndFlags
 $(eval $(1):= -Wl,--start-group $(filter-out -shared, $(2) $(3)) -Wl,--end-group)
endef

ARE_TESTS_AVAILABLE:=$(if $(strip $(wildcard test/*.c)$(wildcard test/*.cpp),), test_availbale,)

define post-test
endef

TEST_RUNNER_ARG_XML:= --gtest_output=xml:
TEST_RUNNER_CMD=unbuffer

CPP_UNIT_TESTER_LIB:=$(GOOGLE_TEST)

$(TEST_SRC_FILE):
	@$(ABS_PRINT_info) "Generating test class $@ to test $(TESTNAME) class."
	@mkdir -p test
	@test -f $@ || printf "|| printf "/*\n\
 * @file Test$(TESTNAME).cpp\n\
 *\n\
 * Copyright %d $(COMPANY). All rights reserved.\n\
 * Use is subject to license terms.\n\
 *\n\
 * \$$Id$$\n\
 * \$$Date$$\n\
 */\n\
 \n\
 // namespace test\n" `date +%Y` > $@

