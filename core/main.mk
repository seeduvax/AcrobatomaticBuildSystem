ifneq ($(wildcard app.cfg),)
include $(PRJROOT)/.abs/core/app.mk
else
include $(PRJROOT)/.abs/core/module.mk
endif
