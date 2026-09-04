# path to the directory containing lua installation
LUA_DIR?=

all:
	pwd
	mkdir -p build
	cd build ; cmake -DCMAKE_INSTALL_PREFIX:PATH=$(INSTDIR) \
		$(if $(LUA_DIR),-DSOL2_LUA_VERSION=5.4.3 -DSOL2_BUILD_LUA=FALSE -DLUA_INCLUDE_DIR:PATH=$(LUA_DIR)/include/ -DLUA_LIBRARIES=$(LUA_DIR)/bin/lua) ..
	cd build ; make 
	
install:
	cd build ; make install

