include ../extlib.mk

SPVERSION:=$(subst ., ,$(VERSION))
VERSIONMAJ:=$(word 1,$(SPVERSION))
VERSIONMED:=$(word 2,$(SPVERSION))
SHORTVERSION=$(VERSIONMAJ)$(VERSIONMED)
$(info DDDDD $(SHORTVERSION))
ifeq ($(ISWINDOWS),true)
$(INSTDIR)/bin/lua$(SHORTVERSION).dll: $(INSTDIR)/import.mk
	gcc -shared  -o $@ $(filter-out $(patsubst %,$(SRCDIR)/src/%.o, lua luac),$(wildcard $(SRCDIR)/src/*.o))

else
$(INSTDIR)/lib/liblua.so: $(INSTDIR)/import.mk
	gcc -shared  -o $@ $(filter-out $(patsubst %,$(SRCDIR)/src/%.o, lua luac),$(wildcard $(SRCDIR)/src/*.o))

endif
