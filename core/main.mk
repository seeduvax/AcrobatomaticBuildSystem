__ABS_VERSION__:=__ABS_MODULE_VERSION_MARKER__
$(info #### Acorbatomatic Build System Core V $(__ABS_VERSION__) ####)
# ensure default target is all
.PHONY: all
all:

ifneq ($(wildcard app.cfg),)
include $(ABSROOT)/core/app.mk
else
include $(ABSROOT)/core/module.mk
endif
