## 
## --------------------------------------------------------------------
## C/C++ profiler services
## ------------------------------------------------------------------------
##
## - PROFILER_TOOL: profiler tool to be used. Currently only few properly
##   packaged profiler are supported:
##     - tracy-0.8.1 (default)
##     - tracy-0.7.8
##     - easy_profiler-2.1.0
PROFILER_TOOL?=tracy-0.8.1
ifeq ($(wildcard app.cfg),app.cfg)
ifeq ($(PROFILER),true)
VFLAVOR+= $(PROFILER_TOOL)
endif
else
## Profiler services  variable
##
## - PROFILER: profiler service activation switch. Set to true to activate
##   profiler support. Default is false
ifeq ($(MAKECMDGOALS),profiler)
PROFILER=true
endif
PROFILER?=false
ifeq ($(PROFILER),true)
PROFILER_FILE:=$(TRDIR)/test/$(MODNAME)
USELIB+=$(PROFILER_TOOL)
CFLAGS+=-DPROFILER_ENABLED
ifneq ($(filter tracy-%,$(PROFILER_TOOL)),)
PROFILER_FILE:=$(PROFILER_FILE).tracy
CFLAGS+=-DTRACY_ENABLE
LINKLIB+=tracy_cli
LDFLAGS+=-pthread -ldl
RUNTIME_PROLOG+=( sleep 1 ; $(EXTLIBDIR)/$(PROFILER_TOOL)/bin/tracy-capture -f -o $(PROFILER_FILE) ) &
RUNTIME_EPILOG+=sleep 1; test -r $(PROFILER_FILE) && make PROFILER=true profiler PROFILER_ARGS=$(PROFILER_FILE) || $(ABS_PRINT_warning) "Profiler record is missing. Check profiling configuration"
RUNTIME_ENV+=TRACY_NO_EXIT=1

tracy:
	@$(ABS_PRINT_info) "Launching tracy profiler gui..."
	@$(EXTLIBDIR)/$(PROFILER_TOOL)/bin/tracy $(PROFILER_ARGS) &

profiler: tracy

endif
ifneq ($(filter easy_profiler-%,$(PROFILER_TOOL)),)
PROFILER_FILE:=$(PROFILER_FILE).prof
CFLAGS+=-DBUILD_WITH_EASY_PROFILER -DPROFILER_COLOR=Green
LINKLIB+=easy_profiler
RUNTIME_ENV+=PROFILER_FILE=$(PROFILER_FILE)
RUNTIME_EPILOG+=test -r $(PROFILER_FILE) && make PROFILER=true profiler PROFILER_ARGS=$(PROFILER_FILE) || $(ABS_PRINT_warning) "Profiler record is missing. Check profiling configuration"

easy_profiler:
	@$(ABS_PRINT_info) "Launching easy profiler gui..."
	@LD_LIBRARY_PATH=$(EXTLIBDIR)/$(PROFILER_TOOL)/lib $(EXTLIBDIR)/$(PROFILER_TOOL)/bin/profiler_gui $(PROFILER_ARGS) &

profiler: easy_profiler

endif
endif
endif
