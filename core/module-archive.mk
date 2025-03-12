# This makefile permit to handle sources files from tar.gz archives.

# external sources as archives
ARCHSRC_SRCFILES=
ARCHSRC_INCLUDE_DIRECTORY=$(TRDIR)/include/$(APPNAME)/$(MODNAME)
ARCHSRC_SRC_DIRECTORY=$(EXT_SRC_DIR)/src
ARCHSRC_EXTRACTED_INFO=$(OBJDIR)/.archsrc_extracted

ifneq ($(SRC_ARCHIVE),)

ARCHSRC_SRC_EXTRACT_ARGS_LIST:=$(subst !,$(_space_),$(subst $(_space_),;,$(SRC_EXTRACT_ARGS)))
ARCHSRC_SRC_EXTRACT_INCLUDES_ARGS_LIST:=$(subst !,$(_space_),$(subst $(_space_),;,$(SRC_EXTRACT_INCLUDES_ARGS)))
ARCHSRC_ALLSRCS:=$(foreach args,$(ARCHSRC_SRC_EXTRACT_ARGS_LIST),$(shell tar -tf $(SRC_ARCHIVE) $(subst ;,$(_space_),$(args)) | grep -v -e "/$$" | cut -f `expr $(patsubst --strip-components=%,%,$(filter --strip-components=%,$(subst ;,$(_space_),$(args)))) + 1`- -d '/' -s))
ARCHSRC_ALLINCLUDES:=$(foreach args,$(ARCHSRC_SRC_EXTRACT_INCLUDES_ARGS_LIST),$(shell tar -tf $(SRC_ARCHIVE) $(subst ;,$(_space_),$(args)) | grep -v -e "/$$" | cut -f `expr $(patsubst --strip-components=%,%,$(filter --strip-components=%,$(subst ;,$(_space_),$(args)))) + 1`- -d '/' -s))
ARCHSRC_SRCFILES=$(patsubst %,$(ARCHSRC_SRC_DIRECTORY)/%,$(ARCHSRC_ALLSRCS))
ARCHSRC_INCLUDESFILES=$(patsubst %,$(ARCHSRC_INCLUDE_DIRECTORY)/%,$(ARCHSRC_ALLINCLUDES))

CFLAGS+=-I$(ARCHSRC_INCLUDE_DIRECTORY) -I$(ARCHSRC_SRC_DIRECTORY)
EXTRA_CFLAGS+=-I$(ARCHSRC_INCLUDE_DIRECTORY)

$(ARCHSRC_EXTRACTED_INFO): $(SRC_ARCHIVE)
	@$(ABS_PRINT_info) "Extraction of $< to $(ARCHSRC_SRC_DIRECTORY)"
	@mkdir -p $(ARCHSRC_SRC_DIRECTORY) $(ARCHSRC_INCLUDE_DIRECTORY)
	@rm -rf $(ARCHSRC_SRC_DIRECTORY)/* $(ARCHSRC_INCLUDE_DIRECTORY)/*
	@$(foreach args,$(ARCHSRC_SRC_EXTRACT_ARGS_LIST),tar -xf $< -C $(ARCHSRC_SRC_DIRECTORY) $(subst ;,$(_space_),$(args)) && ) true
	@$(foreach args,$(ARCHSRC_SRC_EXTRACT_INCLUDES_ARGS_LIST),tar -xf $< -C $(ARCHSRC_INCLUDE_DIRECTORY) $(subst ;,$(_space_),$(args)) && ) true
ifeq ($(ARCHSRC_MODIFY_INCLUDES),true)
	@sed -E -i 's~#include "(.*)"~#include "$(APPNAME)/$(MODNAME)/\1"~g' $(ARCHSRC_INCLUDE_DIRECTORY)/*
endif
	@touch $@

$(ARCHSRC_SRCFILES): $(ARCHSRC_EXTRACTED_INFO)
	@:

$(ARCHSRC_INCLUDESFILES): $(ARCHSRC_EXTRACTED_INFO)
	@:


endif #ifneq ($(SRC_ARCHIVE),)
