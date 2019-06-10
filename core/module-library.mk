include $(ABSROOT)/core/module-crules-vars.mk
include $(PRJROOT)/core/module-adarules.mk
include $(ABSROOT)/core/module-crules.mk
ifneq ($(INCTESTS),)
include $(ABSROOT)/core/module-test.mk
endif
include $(ABSROOT)/core/module-scripts.mk
