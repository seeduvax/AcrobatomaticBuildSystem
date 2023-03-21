$(info Rust module detected)


ifeq ($(ISWINDOWS),true)
SOEXT=.dll
else
SOEXT=.so
endif

# Initialize name of rustc entry file
ifeq ($(ENTRYFILENAME),)
ENTRYFILENAME=lib
endif

# Initialize type of crate
ifeq ($(CRATETYPE),)
CRATETYPE=bin
endif

# Initialize rustc edition
ifeq ($(EDITION),)
EDITION=2018
endif

ifeq ($(CRATETYPE),dylib)
TARGETDIR:=$(TRDIR)/lib
TARGET=lib$(APPNAME)_$(MODNAME)$(SOEXT)
else ifeq ($(CRATETYPE),rlib)
TARGETDIR:=$(TRDIR)/lib
TARGET=lib$(APPNAME)_$(MODNAME).rlib
else
ENTRYFILENAME=main
TARGETDIR:=$(TRDIR)/bin
TARGET=$(APPNAME)_$(MODNAME)
endif

TARGETFILE:=$(TARGETDIR)/$(TARGET)

RUSTSRCFILES:=$(filter %.rs,$(SRCFILES))

RUSTC=rustc

RUSTLIBDIR=$(TRDIR)/lib

RUSTLIBS=$(foreach MOD,$(USEMOD),--extern $(MOD)=$(RUSTLIBDIR)/lib$(APPNAME)_$(MOD).rlib)

RUSTFLAGS+=-L dependency=$(RUSTLIBDIR) $(RUSTLIBS)

ifeq ($(MODE),debug)
RUSTFLAGS+=-g
endif
ifeq ($(MODE),release)
RUSTFLAGS+=-O
endif

$(TARGETFILE): $(RUSTSRCFILES)
	@$(ABS_PRINT_info) "Rust compile $(CRATETYPE) from src/$(ENTRYFILENAME).rs"
	@mkdir -p $(@D)
	@$(RUSTC) --edition=$(EDITION) --crate-type $(CRATETYPE) $(RUSTFLAGS) src/$(ENTRYFILENAME).rs -o $@ && \
        $(ABS_PRINT_info) "Rust crate built: $@"

all-impl:: $(TARGETFILE) 
