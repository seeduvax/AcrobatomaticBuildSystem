
all:
	pwd
	mkdir -p build
	cd build ; cmake -DCMAKE_INSTALL_PREFIX:PATH=$(INSTDIR) ..
	cd build ; make 
	
install:
	cd build ; make install

