# DDS utilities & parameters (TODO should move to a dedicated makefile
# provided by dds package.
IDLC=$(PRJROOT)/make/ddsidl.sh -S -l cpp
DDSDIR=/opt/OpenSpliceDDS

# ---------------------------------------------------------------------
# DDS specific
# TODO move this ine a dds specific makefile
# ---------------------------------------------------------------------
ifeq ($(DDS),)
else
	CFLAGS+= -I$(DDSDIR)/include/dcps/C++/SACPP -I$(DDSDIR)/include \
		-I$(DDSDIR)/include/sys -I$(OBJDIR)/idl \
		$(patsubst %,-I$(OBJDIR)/../%/idl,$(USEMOD))
endif


ifeq ($(DDS),)
else
	IDLOBJS= $(patsubst src/%.idl,$(OBJDIR)/idl/%.o,$(shell find src/ -name '*.idl')) \
		$(patsubst src/%.idl,$(OBJDIR)/idl/%Dcps.o,$(shell find src/ -name '*.idl')) \
		$(patsubst src/%.idl,$(OBJDIR)/idl/%Dcps_impl.o,$(shell find src/ -name '*.idl')) \
		$(patsubst src/%.idl,$(OBJDIR)/idl/%SplDcps.o,$(shell find src/ -name '*.idl'))
endif


# dds specific dependencies (TODO move this elsewhere)
$(OBJDIR)/idl/%.cpp \
$(OBJDIR)/idl/%Dcps.cpp \
$(OBJDIR)/idl/%Dcps_impl.cpp \
$(OBJDIR)/idl/%SplDcps.cpp \
: src/%.idl
	mkdir -p $(OBJDIR)/idl
	$(IDLC) -d $(OBJDIR)/idl $(CFGLAGS) -Isrc -I$(OBJDIR)/idl $^

ifeq ($(DDS),)
else
$(shell find src/ -name '*.cpp'): $(IDLOBJS)

OBJS+= $(IDLOBJS)
	
endif

