# Module to generate website files from:
# typescript files
# other files

TS_OUTPUT_DIR?=etc/$(APPNAME)/www
FILESET_OUTPUT_DIR?=$(TS_OUTPUT_DIR)
FILESET_SRCFILES=$(filter-out %.ts %.tsx,$(SRCFILES))
include $(ABSROOT)/core/module-typescript.mk
include $(ABSROOT)/core/module-fileset.mk