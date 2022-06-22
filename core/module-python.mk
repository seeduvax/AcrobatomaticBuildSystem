## 
## --------------------------------------------------------------------
## python module specific services
## 
## python services variables:
## 
# python interpreter run command
# Tested versions: 2.6 
# Not tested versions: 2.7 and 3.x
##  - PP: path of python interpreter, default is /usr/bin/python
PP:=/usr/bin/python
PYTHON_VERSION:=$(word 2,$(shell $(PP) --version))

# Initialize these environment variables
# so that python interpreter can read their values
# Otherwise ' PYTHONPATH="..."; python ... ' 
# doesn't take into account PYTHONPATH value
export PYTHONPATH=
export LD_LIBRARY_PATH=


# Python debugger
# NB: If the installation of additional
# debuggers is possible, I would suggest to use 
# 'pydb' that has an enhanced debug interface
# than the classic 'pdb'
PDB=pdb
# python path:
# - debug/lib/python : 
#   	localization of the app 
#       package <app>/<module>/<.pyc>
# - extlib/<extern app>/lib/python: 
#   	from USELIB declaration in app.cfg
PY_APP_PATH=$(TRDIR)/lib/python
PY_PATH:=$(PY_APP_PATH)$(subst $(_space_),,$(patsubst %,:$(EXTLIBDIR)/%/lib/python,$(USELIB)))
# LD_LIBRARY_PATH used at dynamic library import
LIB_PATH:=$(TRDIR)lib$(subst $(_space_),,$(patsubst %,:$(EXTLIBDIR)/%/lib,$(USELIB)))
RUNPATH:=$(TRDIR)/bin$(subst $(_space_),,$(patsubst %,:$(EXTLIBDIR)/%/bin,$(USELIB))):$(PATH)
# app package dir
PY_APPDIR=$(PY_APP_PATH)/$(APPNAME)
# sub package dir
PY_MODDIR=$(PY_APPDIR)/$(MODNAME)
# scripts .py directory 
PY_SRCDIR=src/$(APPNAME)/$(MODNAME)
# scripts .py
PY_SRC=$(shell find $(PY_SRCDIR) -name '*.py')
# scripts .pyc
ifneq ($(filter 2.%,$(PYTHON_VERSION)),)
PY_OBJS:=$(patsubst $(PY_SRCDIR)/%.py,$(PY_MODDIR)/%.pyc,$(PY_SRC))
else
PY_OBJS:=$(patsubst $(PY_SRCDIR)/%.py,$(PY_MODDIR)/%.py,$(PY_SRC))
endif
# shell script to run 
PY_MODULE_EXE=$(TRDIR)/bin/$(APPNAME)_$(MODNAME).sh

## 
## python services tagets:
## 
all-impl:: $(PY_OBJS) $(PY_MODULE_EXE)

# MAIN SCRIPT
$(PY_MODULE_EXE):
	@mkdir -p $(@D)
	@printf "#!/bin/sh\n\
realpath=\`readlink -f \$$0\`\n\
bin=\`dirname \$$realpath\`\n\
dir=\`dirname \$$bin\`\n\
# the following command may fail if PYTHONPATH variable isn't initialized. To do so: type 'export PYTHONPATH='\n\
PYTHONPATH=\$$dir/lib/python:\$$PYTHONPATH;LD_LIBRARY_PATH=\$$dir/lib:\$$LD_LIBRARY_PATH;$(PP) \$$dir/lib/python/$(APPNAME)/$(MODNAME) \$$*">$@
	@chmod +x $@

# PYTHON MODULE BYTECODE COMPILATION RULES 
$(PY_APPDIR):
	@mkdir -p $@
	@echo "" >  $@/__init__.py

$(PY_MODDIR): |$(PY_APPDIR) 
	@mkdir $@

$(PY_OBJS): |$(PY_MODDIR)

PP_COMPILE=$(PP) -m py_compile
ifneq ($(filter 2.%,$(PYTHON_VERSION)),)
# file command to transform a .py script to 
# a bytecode .pyc

$(PY_MODDIR)/%.pyc: $(PY_SRCDIR)/%.py
	@$(PP_COMPILE) $<
	@mkdir -p $(@D)
	@mv $<c $@
	@$(ABS_PRINT_info) "$< ---> $@"

else 
$(PY_MODDIR)/%.py: $(PY_SRCDIR)/%.py
	@$(ABS_PRINT_info) "Processing $<..."
	@mkdir -p $(@D)
	@cp $< $@
	cd $(PY_MODDIR) ; $(PP_COMPILE) $@

endif

py-clean:
	rm -rf $(PY_MODDIR) 
	rm -rf $(PY_MODULE_EXE)

clean:: py-clean

# run application
run:: all
	PATH="$(RUNPATH)" PYTHONPATH="$(PY_PATH)" LD_LIBRARY_PATH="$(LIB_PATH)" $(PP) $(PY_MODDIR) $(RUNARGS)

##  - shell [RUNARGS=<arg> [<arg>]*]: run the python shell with module 
##      environment
.PHONY: shell
shell: all
	PATH="$(RUNPATH)" PYTHONPATH="$(PY_PATH)" LD_LIBRARY_PATH="$(LIB_PATH)" $(PP) -i $(PY_MODDIR) $(RUNARGS)

debug:: 
	@make all
	PATH="$(RUNPATH)" PYTHONPATH="$(PY_PATH)" LD_LIBRARY_PATH="$(LIB_PATH)" $(PP) -m $(PDB) $(PY_MODDIR)/__main__.py $(RUNARGS)

##  - pyrun [RUNARGS=<arg> [<arg>]*]: run python
.PHONY:	pyrun
pyrun: all
	PATH="$(RUNPATH)" PYTHONPATH="$(PY_PATH)" LD_LIBRARY_PATH="$(LIB_PATH)" $(PP) $(RUNARGS)


ifneq ($(INCTESTS),)
  include $(ABSROOT)/core/module-testpython.mk
endif

include $(ABSROOT)/core/module-scripts.mk

