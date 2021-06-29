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
	$(EXTLIBDIR)/$(PROFILERTOOL)/bin/tracy &

endif
ifneq ($(filter easy_profiler-%,$(PROFILERTOOL)),)
CFLAGS+=-DPROFILER_EASY -DPROFILER_COLOR=Green
LINKLIB=easy_profiler
endif
endif
endif
