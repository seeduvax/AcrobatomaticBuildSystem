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
USELIB+=$(PROFILERTOOL)
ifneq ($(filter tracy-%,$(PROFILERTOOL)),)
CFLAGS+=-DTRACY_ENABLE
LINKLIB+=tracy_cli

tracy:
	@$(ABS_PRINT_info) "Launching tracy profiler gui..."
	@$(EXTLIBDIR)/$(PROFILERTOOL)/bin/tracy &

profiler: tracy

endif
ifneq ($(filter easy_profiler-%,$(PROFILERTOOL)),)
CFLAGS+=-DPROFILER_EASY -DPROFILER_COLOR=Green
LINKLIB=easy_profiler

easy_profiler:
	@$(ABS_PRINT_info) "Launching easy profiler gui..."
	@LD_LIBRARY_PATH=$(EXTLIBDIR)/$(PROFILERTOOL)/lib $(EXTLIBDIR)/$(PROFILERTOOL)/bin/profiler_gui &

profiler: easy_profiler

endif
endif
endif
