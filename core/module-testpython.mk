## 
## --------------------------------------------------------------------
## python module test services
## 
# Target definition.
TTARGETDIR=$(TRDIR)/test
# tests directory
PY_TSRCDIR=test
PY_TMODDIR=$(TTARGETDIR)/pytest_$(MODNAME)
# xsl transformation (xml jUnit report)
TXTXSL=xunit2txt.xsl
# tests .py
PY_TSRC=$(wildcard $(PY_TSRCDIR)/*.py)
# bytecode tests .pyc
PY_TOBJS=$(patsubst $(PY_TSRCDIR)/%.py,$(PY_TMODDIR)/%.pyc,$(PY_TSRC))
# python path for test targets
PY_TPATH=$(PY_PATH):$(PY_TMODDIR)
PY_UTILS=$(PRJROOT)/.abs/core/python/py_utils

$(PY_TMODDIR): 
	@mkdir -p $@
	@printf "" > $@/__init__.py
	@cp -r $(PY_UTILS) $@/

$(PY_TOBJS): |$(PY_TMODDIR)

$(PY_TMODDIR)/%.pyc: $(PY_TSRCDIR)/%.py
	@$(PP_COMPILE) $<
	@mv $<c $@
	@$(ABS_PRINT_info) "$< ---> $@"

## 
## python module test targets:
## 
##  - test: run tests
test:: all $(PY_TOBJS)
	@( [ -d test ] && rm -f $(TTARGETDIR)/$(APPNAME)_$(MODNAME).xml ) || true 
	@printf "import py_utils; from py_utils.main_exec import main_exec; main_exec(APPNAME='$(APPNAME)',MODNAME='$(MODNAME)',TTARGETDIR='$(TTARGETDIR)',T='$(T)')" > $(PY_TMODDIR)/__main__.py
	(PYTHONPATH="$(PY_TPATH)";LD_LIBRARY_PATH="$(LIB_PATH)" $(PP) $(PY_TMODDIR) 2>&1 | tee $(TTARGETDIR)/$(APPNAME)_$(MODNAME).stdout) || true
	@( [ -d test -a ! -r $(TTARGETDIR)/$(APPNAME)_$(MODNAME).xml ] && $(ABS_PRINT_error) "no test report, test runner exited abnormally." ) || true 
	@( [ -d test -a -r $(TTARGETDIR)/$(APPNAME)_$(MODNAME).xml ] && xsltproc $(PRJROOT)/.abs/core/$(TXTXSL) $(TTARGETDIR)/$(APPNAME)_$(MODNAME).xml ) || true
	@if [ -d test ]; then [ -s $(TTARGETDIR)/$(APPNAME)_$(MODNAME).xml ]; else true; fi

##  - check: alias for test
check:: test

##  - debugtest: run tests in debugger
debugtest:
	PYTHONPATH="$(PY_TPATH)";LD_LIBRARY_PATH="$(LIB_PATH)" $(PP) -m $(PDB) $(PY_TMODDIR)/__main__.py

##  - debugcheck: alias for debugtest
debugcheck: debugtest

testpython-clean:
	rm -rf $(PY_TMODDIR)

clean:: testpython-clean

##  - newtest <tested class name>: create new test file.
ifeq ($(word 1,$(MAKECMDGOALS)),newtest)
$(TESTNAME)=$(word 2,$(MAKECMDGOALS))$(T)

.PHONY: newtest
newtest:
	@$(ABS_PRINT_info) "generating test module 'test/test_$(TESTNAME).py' to test $(TESTNAME) module."
	@mkdir -p test
	@test -f test/test_$(TESTNAME).py || printf "# -*-coding:Utf-8 -*\n\
import unittest\n\
import $(APPNAME).$(MODNAME).$(TESTNAME) as $(TESTNAME)\n\
\n\
class test_$(TESTNAME)(unittest.TestCase):\n\
    def setUp(self):\n\
        pass\n\
\n\
    def tearDown(self):\n\
        pass\n\
\n\
#    def test_subcase_1(self):\n\
#        self.assertTrue(True)\n\
#\n\
#    def test_subcase_2(self):\n\
#        self.assertEqual(True)\n\
\n\
if __name__ == '__main__':\n\
    unittest.main()\n" > test/test_$(TESTNAME).py

$(TESTNAME):

endif
