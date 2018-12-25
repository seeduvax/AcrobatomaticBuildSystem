include $(PRJROOT)/.abs/core/module-crules-vars.mk
include $(PRJROOT)/.abs/core/module-crules.mk
ifneq ($(INCTESTS),)
include $(PRJROOT)/.abs/core/module-test.mk
endif
include $(PRJROOT)/.abs/core/module-scripts.mk
