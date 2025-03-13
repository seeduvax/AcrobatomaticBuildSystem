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
##  - SRC_ARCHIVES_INCLUDE_NAME: Include the archive name in extracted directories.
ARCHSRC_SRCFILES=
ARCHSRC_EXTRACTED_INFO=$(EXT_MODSRC_DIR)/.archsrc_extracted
ARCHSRC_INCLUDES_EXTRACTED=$(OBJDIR)/.archsrc_includes_extracted
SRC_ARCHIVES+=$(SRC_ARCHIVE)

ifneq ($(SRC_ARCHIVES),)
SRC_ARCHIVES:=$(sort $(SRC_ARCHIVES))

ARCHSRC_INCLUDE_NAME=
ifeq ($(SRC_ARCHIVES_INCLUDE_NAME),true)
ARCHSRC_INCLUDE_NAME=true
endif

define getArchiveName
$(patsubst %.tar.gz,%,$(notdir $(1)))
endef
# macro to list all files of an archive
# - 1: archive path
# - 2: tar arguments
define getAllTarFiles
$(patsubst %,$(if $(ARCHSRC_INCLUDE_NAME),$(call getArchiveName,$(1))/,)%,\
$(shell tar -tf $(1) $(subst ;,$(_space_),$(2)) | grep -v -e "/$$" | cut -f `expr $(patsubst --strip-components=%,%,$(filter --strip-components=%,$(subst ;,$(_space_),$(2)))) + 1`- -d '/' -s))
endef

ARCHSRC_SRC_EXTRACT_ARGS_LIST:=$(subst !,$(_space_),$(subst $(_space_),;,$(SRC_EXTRACT_ARGS)))
ARCHSRC_SRC_EXTRACT_INCLUDES_ARGS_LIST:=$(subst !,$(_space_),$(subst $(_space_),;,$(SRC_EXTRACT_INCLUDES_ARGS)))
ARCHSRC_ALLSRCS:=$(foreach archive,$(SRC_ARCHIVES),$(foreach args,$(ARCHSRC_SRC_EXTRACT_ARGS_LIST),$(call getAllTarFiles,$(archive),$(args))))
ARCHSRC_ALLINCLUDES:=$(foreach archive,$(SRC_ARCHIVES),$(foreach args,$(ARCHSRC_SRC_EXTRACT_INCLUDES_ARGS_LIST),$(call getAllTarFiles,$(archive),$(args))))
ARCHSRC_SRCFILES=$(patsubst %,$(EXT_MODSRC_DIR)/%,$(ARCHSRC_ALLSRCS))
ARCHSRC_INCLUDESFILES=$(patsubst %,$(TR_MOD_INCLUDE_DIR)/%,$(ARCHSRC_ALLINCLUDES))

ADDITIONNAL_CFLAGS=-I$(TR_MOD_INCLUDE_DIR) -I$(EXT_MODSRC_DIR)
ifeq ($(ARCHSRC_INCLUDE_NAME),true)
ADDITIONNAL_CFLAGS+=$(foreach archive,$(SRC_ARCHIVES),-I$(TR_MOD_INCLUDE_DIR)/$(call getArchiveName,$(archive)))
endif
CFLAGS+=$(ADDITIONNAL_CFLAGS)
EXTRA_CFLAGS+=$(ADDITIONNAL_CFLAGS)

$(ARCHSRC_EXTRACTED_INFO): $(SRC_ARCHIVES)
	@$(ABS_PRINT_info) "Extraction sources of archives"
	@mkdir -p $(EXT_MODSRC_DIR)
	@rm -rf $(EXT_MODSRC_DIR)/*
	@$(foreach archive,$(SRC_ARCHIVES), $(ABS_PRINT_info) "  Extraction sources of $(archive) to $(EXT_MODSRC_DIR)" &&\
		outputDir="$(EXT_MODSRC_DIR)$(if $(ARCHSRC_INCLUDE_NAME),/$(call getArchiveName,$(archive)),)" && \
		mkdir -p $$outputDir && \
		$(foreach args,$(ARCHSRC_SRC_EXTRACT_ARGS_LIST),\
		tar -xf $(archive) -C $$outputDir $(subst ;,$(_space_),$(args)) && )) true
	@touch $@
	
$(ARCHSRC_INCLUDES_EXTRACTED): $(SRC_ARCHIVES)
	@$(ABS_PRINT_info) "Extraction includes of archives"
	@mkdir -p $(TR_MOD_INCLUDE_DIR)
	@rm -rf $(TR_MOD_INCLUDE_DIR)/*
	@$(foreach archive,$(SRC_ARCHIVES),$(ABS_PRINT_info) "  Extraction includes of $(archive) to $(TR_MOD_INCLUDE_DIR)" &&\
		outputDir="$(TR_MOD_INCLUDE_DIR)$(if $(ARCHSRC_INCLUDE_NAME),/$(call getArchiveName,$(archive)),)" && \
		mkdir -p $$outputDir && \
		$(foreach args,$(ARCHSRC_SRC_EXTRACT_INCLUDES_ARGS_LIST),\
		tar -xf $(archive) -C $$outputDir $(subst ;,$(_space_),$(args)) && )) true
ifeq ($(ARCHSRC_MODIFY_INCLUDES),true)
	@sed -E -i 's~#include "(.*)"~#include "$(APPNAME)/$(MODNAME)/\1"~g' $(TR_MOD_INCLUDE_DIR)/*
endif
	@touch $@

$(ARCHSRC_SRCFILES): $(ARCHSRC_EXTRACTED_INFO) $(ARCHSRC_INCLUDES_EXTRACTED)
	@:

$(ARCHSRC_INCLUDESFILES): $(ARCHSRC_EXTRACTED_INFO) $(ARCHSRC_INCLUDES_EXTRACTED)
	@:


endif #ifneq ($(SRC_ARCHIVES),)
