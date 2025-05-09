include ../extlib.mk

ifeq ($(ISWINDOWS),true)
LDFLAGS:=-lregex -lws2_32
else
LDFLAGS:=-ldl -lrt
endif

$(INSTDIR)/bin/%: $(PRJDIR)/%.cpp $(INSTDIR)/import.mk
	@echo "Adding extra macro to helpers..."
	@cat $(PRJDIR)/extra.h >> $(INSTDIR)/include/cppunit/extensions/HelperMacros.h
	@echo "Compiling ${<F}..."
	@mkdir -p ${@D}
	@g++ $< -o $@ -I$(INSTDIR)/include -L$(INSTDIR)/lib -lcppunit $(LDFLAGS)
