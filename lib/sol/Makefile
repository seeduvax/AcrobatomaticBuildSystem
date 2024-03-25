include ../extlib.mk

$(INSTDIR)/lib/liblua.so: $(INSTDIR)/import.mk
	gcc -shared  -o $@ $(filter-out $(patsubst %,$(SRCDIR)/src/%.o, lua luac),$(wildcard $(SRCDIR)/src/*.o))

