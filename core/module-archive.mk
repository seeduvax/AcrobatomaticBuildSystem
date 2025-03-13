# This makefile permit to handle sources files from tar.gz archives.

# external sources as archives

## --------------------
## Sources Archives
## --------------------
## Variables
##     - SRC_ARCHIVE: path to the archive containing source files.
##     - SRC_EXTRACT_ARGS: arguments for tar command to extract sources files
##     - SRC_EXTRACT_INCLUDES_ARGS: arguments for tar command to extract includes files
ARCHSRC_SRCFILES=
ARCHSRC_EXTRACTED_INFO=$(OBJDIR)/.archsrc_extracted

ifneq ($(SRC_ARCHIVE),)

ARCHSRC_SRC_EXTRACT_ARGS_LIST:=$(subst !,$(_space_),$(subst $(_space_),;,$(SRC_EXTRACT_ARGS)))
ARCHSRC_SRC_EXTRACT_INCLUDES_ARGS_LIST:=$(subst !,$(_space_),$(subst $(_space_),;,$(SRC_EXTRACT_INCLUDES_ARGS)))
ARCHSRC_ALLSRCS:=$(foreach args,$(ARCHSRC_SRC_EXTRACT_ARGS_LIST),$(shell tar -tf $(SRC_ARCHIVE) $(subst ;,$(_space_),$(args)) | grep -v -e "/$$" | cut -f `expr $(patsubst --strip-components=%,%,$(filter --strip-components=%,$(subst ;,$(_space_),$(args)))) + 1`- -d '/' -s))
ARCHSRC_ALLINCLUDES:=$(foreach args,$(ARCHSRC_SRC_EXTRACT_INCLUDES_ARGS_LIST),$(shell tar -tf $(SRC_ARCHIVE) $(subst ;,$(_space_),$(args)) | grep -v -e "/$$" | cut -f `expr $(patsubst --strip-components=%,%,$(filter --strip-components=%,$(subst ;,$(_space_),$(args)))) + 1`- -d '/' -s))
ARCHSRC_SRCFILES=$(patsubst %,$(EXT_MODSRC_DIR)/%,$(ARCHSRC_ALLSRCS))
ARCHSRC_INCLUDESFILES=$(patsubst %,$(TR_INCLUDE_DIR)/%,$(ARCHSRC_ALLINCLUDES))

CFLAGS+=-I$(TR_INCLUDE_DIR) -I$(EXT_MODSRC_DIR)
EXTRA_CFLAGS+=-I$(TR_INCLUDE_DIR)

$(ARCHSRC_EXTRACTED_INFO): $(SRC_ARCHIVE)
	@$(ABS_PRINT_info) "Extraction of $< to $(EXT_MODSRC_DIR)"
	@mkdir -p $(EXT_MODSRC_DIR) $(TR_INCLUDE_DIR)
	@rm -rf $(EXT_MODSRC_DIR)/* $(TR_INCLUDE_DIR)/*
	@$(foreach args,$(ARCHSRC_SRC_EXTRACT_ARGS_LIST),tar -xf $< -C $(EXT_MODSRC_DIR) $(subst ;,$(_space_),$(args)) && ) true
	@$(foreach args,$(ARCHSRC_SRC_EXTRACT_INCLUDES_ARGS_LIST),tar -xf $< -C $(TR_INCLUDE_DIR) $(subst ;,$(_space_),$(args)) && ) true
ifeq ($(ARCHSRC_MODIFY_INCLUDES),true)
	@sed -E -i 's~#include "(.*)"~#include "$(APPNAME)/$(MODNAME)/\1"~g' $(TR_INCLUDE_DIR)/*
endif
	@touch $@

$(ARCHSRC_SRCFILES): $(ARCHSRC_EXTRACTED_INFO)
	@:

$(ARCHSRC_INCLUDESFILES): $(ARCHSRC_EXTRACTED_INFO)
	@:


endif #ifneq ($(SRC_ARCHIVE),)
