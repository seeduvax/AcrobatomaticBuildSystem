
all:
	pwd
	@echo "/////////////////////// build /////////////////////"
	@echo $(INSTDIR)
	mkdir -p build
	cd build ; cmake -DCMAKE_INSTALL_PREFIX=$(INSTDIR) ..
	cd build ; make Makefile
	
install:
	@echo "/////////////////////// install /////////////////////"
	cd build ; make install

