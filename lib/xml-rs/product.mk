
all:
	cargo build --release

install:
	mkdir -p $(INSTDIR)/bin
	mkdir -p $(INSTDIR)/lib
	cp ./target/release/xml-analyze $(INSTDIR)/bin
	cp ./target/release/libxml.rlib $(INSTDIR)/lib

