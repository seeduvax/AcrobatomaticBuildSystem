# ensure default target is all
.PHONY: all
all:

ifneq ($(wildcard app.cfg),)
include $(ABSROOT)/core/app.mk
else
include $(ABSROOT)/core/module.mk
endif
