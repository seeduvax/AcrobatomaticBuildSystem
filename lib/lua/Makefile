include ../extlib.mk

ifeq ($(ISWINDOWS),true)
$(INSTDIR)/bin/lua$(SHORTVERSION).dll: $(INSTDIR)/import.mk
	gcc -shared  -o $@ $(filter-out $(patsubst %,$(SRCDIR)/src/%.o, lua luac),$(wildcard $(SRCDIR)/src/*.o))

$(INSTDIR)/bin/luap: $(INSTDIR)/bin/lua$(SHORTVERSION).dll
	wget $(LUAPSRCURL) -O luap.tar.gz
	tar xvzf luap.tar.gz
	make -C luap*/ PREFIX=$(INSTDIR) VERSION=$(MEDVERSION) LUA_CFLAGS="-I$(INSTDIR)/include" LUA_LDFLAGS="-L$(INSTDIR)/bin -llua$(SHORTVERSION)" install
	rm -rf luap*

else
$(INSTDIR)/lib/liblua.so: $(INSTDIR)/import.mk
	gcc -shared  -o $@ $(filter-out $(patsubst %,$(SRCDIR)/src/%.o, lua luac),$(wildcard $(SRCDIR)/src/*.o))

$(INSTDIR)/bin/luap: $(INSTDIR)/lib/liblua.so
	wget $(LUAPSRCURL) -O luap.tar.gz
	tar xvzf luap.tar.gz
	make -C luap*/ PREFIX=$(INSTDIR) LUA_CFLAGS="-I$(INSTDIR)/include" LUA_LDFLAGS="-L$(INSTDIR)/lib -llua" install
	rm -rf luap*

endif

$(INSTDIR)/lib/lua/$(MEDVERSION)/argparse.lua: $(INSTDIR)/import.mk
	wget $(ARGPARSESRCURL) -O argparse.tar.gz
	tar xvzf argparse.tar.gz
	cp argparse*/src/argparse.lua $(INSTDIR)/lib/lua/$(MEDVERSION)/
	rm -rf argparse*

