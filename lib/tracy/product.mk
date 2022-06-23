INCLUDES:= \
./TracyOpenCL.hpp \
./TracyLua.hpp \
./TracyD3D12.hpp \
./TracyD3D11.hpp \
./Tracy.hpp \
./TracyOpenGL.hpp \
./TracyC.h \
./TracyVulkan.hpp

INCLUDES_COMMON:= \
./common/TracyAlloc.hpp \
./common/TracyMutex.hpp \
./common/TracyAlign.hpp \
./common/TracyColor.hpp \
./common/TracyQueue.hpp \
./common/TracyForceInline.hpp \
./common/TracyApi.h \
./common/TracySystem.hpp \
./common/TracyProtocol.hpp

INCLUDES_CLIENT:=\
./client/tracy_rpmalloc.hpp \
./client/TracyFastVector.hpp \
./client/TracyScoped.hpp \
./client/TracyProfiler.hpp \
./client/TracyCallstack.hpp \
./client/tracy_concurrentqueue.h \
./client/TracyCallstack.h \
./client/TracySysTime.hpp \
./client/TracyLock.hpp \
./client/tracy_SPSCQueue.h

all:
	cd capture/build/unix ; make
	cd csvexport/build/unix ; make
	cd profiler/build/unix ; make
	g++ -shared -o libtracy_cli.so -fPIC -DTRACY_ENABLE TracyClient.cpp

install:
	mkdir -p $(INSTDIR)/bin
	mkdir -p $(INSTDIR)/lib
	mkdir -p $(INSTDIR)/include
	mkdir -p $(INSTDIR)/include/common
	mkdir -p $(INSTDIR)/include/client
	cp capture/build/unix/capture-release $(INSTDIR)/bin/tracy-capture
	cp csvexport/build/unix/csvexport-release $(INSTDIR)/bin/tracy-csvexport
	cp profiler/build/unix/Tracy-release $(INSTDIR)/bin/tracy
	cp libtracy_cli.so $(INSTDIR)/lib/
	cp $(INCLUDES) $(INSTDIR)/include/
	cp $(INCLUDES_COMMON) $(INSTDIR)/include/common
	cp $(INCLUDES_CLIENT) $(INSTDIR)/include/client

