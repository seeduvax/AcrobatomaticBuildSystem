$(info DDDDD rust)


ifeq ($(ISWINDOWS),true)
SOEXT=.dll
else
SOEXT=.so
endif

ifeq ($(CRATETYPE),dylib)
TARGETDIR:=$(TRDIR)/lib
TARGET=lib$(APPNAME)_$(MODNAME)$(SOEXT)
else
TARGETDIR=:=$(TRDIR)/bin
TARGET=$(APPNAME)_$(MODNAME)
endif

TARGETFILE:=$(TARGETDIR)/$(TARGET)

RUSTSRCFILES:=$(filter %.rs,$(SRCFILES))

RUSTC=rustc

ifeq ($(MODE),debug)
RUSTFLAGS+=-g
endif
ifeq ($(MODE),release)
RUSTFLAGS+=-O
endif


$(info DDDDD $(TARGETFILE))


$(TARGETFILE): $(RUSTSRCFILES)
	@$(ABS_PRINT_info) "Rust compile from src/$(APPNAME).rs"
	@mkdir -p $(@D)
	@$(RUSTC) --crate-type $(CRATETYPE) $(RUSTFLAGS) src/$(APPNAME).rs -o $@ && \
        $(ABS_PRINT_info) "Rust crate built: $@"

all-impl:: $(TARGETFILE) 
