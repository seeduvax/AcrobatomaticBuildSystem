## 
## --------------------------------------------------------------------
## C/C++ profiler services
## ------------------------------------------------------------------------
##
ifeq ($(ABS_FROMAPP),true)
ifeq ($(PROFILER),true)
VFLAVOR+=.prof
endif
else
## Profiler services  variable
##
## - PROFILER: profiler service activation switch. Set to true to activate
##   profiler support. Default is false
ifeq ($(MAKECMDGOALS),tracy)
PROFILER=true
endif
PROFILER?=false
## - PROFILERTOOL: profiler tool to be used. Currently only few properly 
##   packaged profiler are supported:
##     - tracy-0.7.8 (default)
##     - easy_profiler-2.1.0

PROFILERTOOL?=tracy-0.7.8
ifeq ($(PROFILER),true)
PROFILER_FILE=$(TRDIR)/test/$(MODNAME)-$(shell date '+%Y-%m-%d_%H-%M-%S').prof
USELIB+=$(PROFILERTOOL)
ifneq ($(filter tracy-%,$(PROFILERTOOL)),)
CFLAGS+=-DTRACY_ENABLE
LINKLIB+=tracy_cli
LDFLAGS+=-pthread -ldl
RUNTIME_PROLOG+=$(EXTLIBDIR)/$(PROFILERTOOL)/bin/tracy-capture -o $(PROFILER_FILE) & sleep 2 ;

tracy:
	@$(ABS_PRINT_info) "Launching tracy profiler gui..."
	@$(EXTLIBDIR)/$(PROFILERTOOL)/bin/tracy $(word 1,$(shell ls -t $(TRDIR)/test/$(MODNAME)-*.prof)) &

profiler: tracy

endif
ifneq ($(filter easy_profiler-%,$(PROFILERTOOL)),)
CFLAGS+=-DBUILD_WITH_EASY_PROFILER -DPROFILER_COLOR=Green
LINKLIB=easy_profiler
RUNTIME_ENV+=PROFILER_FILE=$(PROFILER_FILE)

easy_profiler:
	@$(ABS_PRINT_info) "Launching easy profiler gui..."
	@LD_LIBRARY_PATH=$(EXTLIBDIR)/$(PROFILERTOOL)/lib $(EXTLIBDIR)/$(PROFILERTOOL)/bin/profiler_gui $(word 1,$(shell ls -t $(TRDIR)/test/$(MODNAME)-*.prof)) &

profiler: easy_profiler

endif
endif
endif
