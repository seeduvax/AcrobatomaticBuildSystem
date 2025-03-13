# This makefile permit to handle sources files from tar.gz archives.

# external sources as archives
## 
## --------------------
## Sources Archives
## --------------------
## Variables
##  - SRC_ARCHIVE: path to the archive containing source files.
##  - SRC_ARCHIVES: path to the archives containing source files.
##  - SRC_EXTRACT_ARGS: arguments for tar command to extract sources files
##  - SRC_EXTRACT_INCLUDES_ARGS: arguments for tar command to extract includes files
ARCHSRC_SRCFILES=
ARCHSRC_EXTRACTED_INFO=$(EXT_MODSRC_DIR)/.archsrc_extracted
SRC_ARCHIVES+=$(SRC_ARCHIVE)

ifneq ($(SRC_ARCHIVES),)
SRC_ARCHIVES:=$(sort $(SRC_ARCHIVES))
# macro to list all files of an archive
# - 1: archive path
# - 2: tar arguments
define getAllTarFiles
$(shell tar -tf $(1) $(subst ;,$(_space_),$(2)) | grep -v -e "/$$" | cut -f `expr $(patsubst --strip-components=%,%,$(filter --strip-components=%,$(subst ;,$(_space_),$(2)))) + 1`- -d '/' -s)
endef

ARCHSRC_SRC_EXTRACT_ARGS_LIST:=$(subst !,$(_space_),$(subst $(_space_),;,$(SRC_EXTRACT_ARGS)))
ARCHSRC_SRC_EXTRACT_INCLUDES_ARGS_LIST:=$(subst !,$(_space_),$(subst $(_space_),;,$(SRC_EXTRACT_INCLUDES_ARGS)))
ARCHSRC_ALLSRCS:=$(foreach archive,$(SRC_ARCHIVES),$(foreach args,$(ARCHSRC_SRC_EXTRACT_ARGS_LIST),$(call getAllTarFiles,$(archive),$(args))))
ARCHSRC_ALLINCLUDES:=$(foreach archive,$(SRC_ARCHIVES),$(foreach args,$(ARCHSRC_SRC_EXTRACT_INCLUDES_ARGS_LIST),$(call getAllTarFiles,$(archive),$(args))))
ARCHSRC_SRCFILES=$(patsubst %,$(EXT_MODSRC_DIR)/%,$(ARCHSRC_ALLSRCS))
ARCHSRC_INCLUDESFILES=$(patsubst %,$(TR_MOD_INCLUDE_DIR)/%,$(ARCHSRC_ALLINCLUDES))
CFLAGS+=-I$(TR_MOD_INCLUDE_DIR) -I$(EXT_MODSRC_DIR)
EXTRA_CFLAGS+=-I$(TR_MOD_INCLUDE_DIR)

$(ARCHSRC_EXTRACTED_INFO): $(SRC_ARCHIVES)
	@$(ABS_PRINT_info) "Extraction of archives"
	@mkdir -p $(EXT_MODSRC_DIR) $(TR_MOD_INCLUDE_DIR)
	@rm -rf $(EXT_MODSRC_DIR)/* $(TR_MOD_INCLUDE_DIR)/*
	@$(foreach archive,$(SRC_ARCHIVES), $(ABS_PRINT_info) "  Extraction sources of $(archive) to $(EXT_MODSRC_DIR)" &&\
		$(foreach args,$(ARCHSRC_SRC_EXTRACT_ARGS_LIST),\
		tar -xf $(archive) -C $(EXT_MODSRC_DIR) $(subst ;,$(_space_),$(args)) && )) true
	@$(foreach archive,$(SRC_ARCHIVES),$(ABS_PRINT_info) "  Extraction includes of $(archive) to $(TR_MOD_INCLUDE_DIR)" &&\
		$(foreach args,$(ARCHSRC_SRC_EXTRACT_INCLUDES_ARGS_LIST),\
		tar -xf $(archive) -C $(TR_MOD_INCLUDE_DIR) $(subst ;,$(_space_),$(args)) && )) true
ifeq ($(ARCHSRC_MODIFY_INCLUDES),true)
	@sed -E -i 's~#include "(.*)"~#include "$(APPNAME)/$(MODNAME)/\1"~g' $(TR_MOD_INCLUDE_DIR)/*
endif
	@touch $@

$(ARCHSRC_SRCFILES): $(ARCHSRC_EXTRACTED_INFO)
	@:

$(ARCHSRC_INCLUDESFILES): $(ARCHSRC_EXTRACTED_INFO)
	@:


endif #ifneq ($(SRC_ARCHIVES),)
