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
## 
## Targets
##  - generatePatches: generate patches in patches directory.

SRC_ARCHIVES+=$(SRC_ARCHIVE)

ARCHSRC_SRCFILES=
ARCHSRC_EXTRACTED_INFO=$(EXT_MODSRC_DIR)/.archsrc_extracted
ARCHSRC_INCLUDES_EXTRACTED=$(OBJDIR)/.archsrc_includes_extracted
ARCHSRC_GENE_PATCHES_EXTRACT_DIR=$(OBJDIR)/extsrc_for_patches
ARCHSRC_GENE_PATCHES_EXTRACT_INFO=$(ARCHSRC_GENE_PATCHES_EXTRACT_DIR)/.extracted
ARCHSRC_GENE_PATCHES_OUT=patches

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

# Macro to extract archives
# 1: Destination directory
# 2: extraction arguments
define extractArchives
$(foreach archive,$(SRC_ARCHIVES), $(ABS_PRINT_info) "  Extraction sources of $(archive) to $(1)" &&\
	outputDir="$(1)$(if $(ARCHSRC_INCLUDE_NAME),/$(call getArchiveName,$(archive)),)" && \
	mkdir -p $$outputDir && \
	$(foreach args,$(2),\
	tar -xf $(archive) -C $$outputDir $(subst ;,$(_space_),$(args)) && )) true
endef

$(ARCHSRC_EXTRACTED_INFO): $(SRC_ARCHIVES)
	@$(ABS_PRINT_info) "Extraction sources of archives"
	@mkdir -p $(EXT_MODSRC_DIR)
	@rm -rf $(EXT_MODSRC_DIR)/*
	@$(call extractArchives,$(EXT_MODSRC_DIR),$(ARCHSRC_SRC_EXTRACT_ARGS_LIST))
	@touch $@
	
$(ARCHSRC_INCLUDES_EXTRACTED): $(SRC_ARCHIVES)
	@$(ABS_PRINT_info) "Extraction includes of archives"
	@mkdir -p $(TR_MOD_INCLUDE_DIR)
	@rm -rf $(TR_MOD_INCLUDE_DIR)/*
	@$(call extractArchives,$(TR_MOD_INCLUDE_DIR),$(ARCHSRC_SRC_EXTRACT_INCLUDES_ARGS_LIST))
ifeq ($(ARCHSRC_MODIFY_INCLUDES),true)
	@sed -E -i 's~#include "(.*)"~#include "$(APPNAME)/$(MODNAME)/\1"~g' $(TR_MOD_INCLUDE_DIR)/*
endif
	@touch $@

$(ARCHSRC_GENE_PATCHES_EXTRACT_INFO): $(ARCHSRC_EXTRACTED_INFO) $(ARCHSRC_INCLUDES_EXTRACTED)
	@$(ABS_PRINT_info) "Extraction of archives to directory for patches"
	@mkdir -p $(@D)/includes
	@mkdir -p $(@D)/src
	@rm -rf $(@D)/*
	@$(call extractArchives,$(@D)/src,$(ARCHSRC_SRC_EXTRACT_ARGS_LIST))
	@$(call extractArchives,$(@D)/includes,$(ARCHSRC_SRC_EXTRACT_INCLUDES_ARGS_LIST))
ifeq ($(ARCHSRC_MODIFY_INCLUDES),true)
	@sed -E -i 's~#include "(.*)"~#include "$(APPNAME)/$(MODNAME)/\1"~g' $(@D)/*
endif
	@touch $@

$(ARCHSRC_SRCFILES): $(ARCHSRC_EXTRACTED_INFO) $(ARCHSRC_INCLUDES_EXTRACTED)
	@:

$(ARCHSRC_INCLUDESFILES): $(ARCHSRC_EXTRACTED_INFO) $(ARCHSRC_INCLUDES_EXTRACTED)
	@:

# macro to generate patches
# 1: sources originals directory
# 2: sources modified directory
define generatePatchesFor
for file in `find $1 -type f`; do \
	relativePath=`echo $$file | sed 's~$(1)/~~g'` && \
	if [ `diff -q $$file $2/$$relativePath | wc -l` -ne 0 ]; then \
		$(ABS_PRINT_info) "Generating patch for $$relativePath";\
		mkdir -p $(ARCHSRC_GENE_PATCHES_OUT)/`dirname $$relativePath` && \
		diff --label $$relativePath --label $$relativePath -Nau $$file $2/$$relativePath > $(ARCHSRC_GENE_PATCHES_OUT)/$$relativePath.patch || :; \
	fi; \
done
endef

$(info Add generation pached target)
generatePatches: $(ARCHSRC_GENE_PATCHES_EXTRACT_INFO)
	@$(call generatePatchesFor,$(<D)/src,$(EXT_MODSRC_DIR))
	@$(call generatePatchesFor,$(<D)/includes,$(TR_MOD_INCLUDE_DIR))
else
generatePatches:
	@$(ABS_PRINT_warning) "Cannot generate patch without source archives"

endif #ifneq ($(SRC_ARCHIVES),)
