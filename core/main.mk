__ABS_VERSION__:=__ABS_MODULE_VERSION_MARKER__
$(info # Acrobatomatic Build System Core V $(__ABS_VERSION__))

ifeq ($(MAKE_RESTARTS),20)
$(error  Too many restart of make ($(MAKE_RESTARTS)) ! A error occured !)
endif

# ensure default target is all
.PHONY: all
all:

ifneq ($(wildcard app.cfg),)
include $(ABSROOT)/core/app.mk
else
include $(ABSROOT)/core/module.mk
endif

ifneq ($(ABS_FATAL),)
$(error ABS aborting on fatal error)
endif
$(eval $(abs_post_definitions))
