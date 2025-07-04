__ABS_VERSION__:=__ABS_MODULE_VERSION_MARKER__

# workaround not so smart PRJROOT definition from bootstrap.mk
# Don't want to update bootstrap to better abs upgrade in projects without side
# effects.
PRJROOT:=$(abspath $(PRJROOT))

ifeq ($(MAKE_RESTARTS),)
ifeq ($(MAKELEVEL),0)
$(info # Acrobatomatic Build System Core V $(__ABS_VERSION__))
$(info To show debug logs, use variable ABS_LOG_LEVEL=debug)
endif
endif

ifeq ($(MAKE_RESTARTS),20)
$(error  Too many restart of make ($(MAKE_RESTARTS)) ! A error occured !)
endif

# ensure default target is all
.PHONY: all
all:

# remove a lot of default suffixes not used by abs.
.SUFFIXES:
	@:

ifneq ($(wildcard app.cfg),)
ABS_FROMAPP:=true
include $(ABSROOT)/core/app.mk
else
ABS_FROMMODULE:=true
include $(ABSROOT)/core/module.mk
endif

ifneq ($(ABS_FATAL),)
$(error ABS aborting on fatal error)
endif
$(eval $(abs_post_definitions))
