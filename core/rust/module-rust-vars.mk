# ---------------------------------------------------------------------
# Common Rust variables and dependency management
# ---------------------------------------------------------------------
RUST_VERSION?=1.93.0
USE_CARGO?=false

# Initialize type of crate
ifeq ($(CRATETYPE),)
ifneq ($(wildcard src/lib.rs),)
CRATETYPE=rlib
else
CRATETYPE=bin
endif
endif

# CRATE Type for doc generation or test execution
ONE_CRATETYPE=$(if $(filter bin,$(CRATETYPE)),bin,lib)

ifeq ($(ISWINDOWS),true)
SOEXT=.dll
EXEEXT=.exe
else #($(ISWINDOWS),false)
EXEEXT=
SOEXT=.so
endif #($(ISWINDOWS),false)

TARGET_NAME=
ifeq ($(APPNAME),$(MODNAME))
TARGET_NAME:=$(APPNAME)
else
TARGET_NAME:=$(APPNAME)_$(MODNAME)
endif

RUSTSRCFILES:=$(filter %.rs,$(SRCFILES))

RUST_TARGET_FILE_BIN:=$(TRDIR)/bin/$(TARGET_NAME)$(EXEEXT)
RUST_TARGET_FILE_RLIB:=$(TRDIR)/lib/lib$(TARGET_NAME).rlib
RUST_TARGET_FILE_SO:=$(TRDIR)/lib/libc$(TARGET_NAME)$(SOEXT)
RUST_TARGET_FILE_RUST_SO:=$(TRDIR)/lib/lib$(TARGET_NAME)$(SOEXT)

define getRustTargetName
$(if $(filter rlib,$(1)),$(RUST_TARGET_FILE_RLIB),\
$(if $(filter dylib,$(1)),$(RUST_TARGET_FILE_RUST_SO),\
$(if $(filter cdylib,$(1)),$(RUST_TARGET_FILE_SO),\
$(RUST_TARGET_FILE_BIN))))
endef

RUST_TARGET_FILES:=$(foreach crateType,$(CRATETYPE),$(call getRustTargetName,$(crateType)))
RUST_TARGET_FILES+=$(patsubst src/%.rs,$(TRDIR)/src/$(APPNAME)_$(MODNAME)/src/%.rs,$(filter %.rs,$(SRCFILES)))