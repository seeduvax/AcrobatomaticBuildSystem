FMIINCDIR=fmi-standard-$(VERFMI)/headers

all: $(FMIINCDIR)
	g++ $(CFLAGS) -c cppfmu_cs.cpp -o cppfmu_cs.o
	g++ $(CFLAGS) -c fmi_functions.cpp -o fmi_function.o
	g++ $(LDFLAGS) -o libcppfmu.so *.o

$(FMIINCDIR):
	wget $(FMIHEADERURL) -O fmi-$(VERFMI).tar.gz
	tar xvzf fmi-$(VERFMI).tar.gz

CFLAGS=-fPIC -I$(FMIINCDIR)
LDFLAGS=-shared


install:
	mkdir -p $(INSTDIR)/include/cppfmu
	mkdir -p $(INSTDIR)/lib
	cp *.hpp $(INSTDIR)/include/cppfmu
	cp $(FMIINCDIR)/*.h $(INSTDIR)/include
	cp libcppfmu.so $(INSTDIR)/lib

