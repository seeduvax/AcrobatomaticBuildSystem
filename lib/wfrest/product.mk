
all:
	pwd
	mkdir -p build
	cd build ; cmake -DCMAKE_INSTALL_PREFIX=$(INSTDIR) -DWorkflow_DIR=../../workflow-0.11.9/ ..
	cd build ; make 
	
install:
	cd build ; make install

