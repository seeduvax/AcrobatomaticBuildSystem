### MODS dependencies variables:
### USEMOD (optional/obsolete): list of project mods needed by this mod and linked with
### LINKLIB: list of libs/mods needed by this mod and linked with. The format is $(APPNAME)_$(MODNAME) for module or $(APPNAME) for entire lib.
### INCLUDE_MODS: list of libs/mods needed by this mod but not linked with. The format is $(APPNAME)_$(MODNAME) for module or $(APPNAME) for entire lib.
###
### TESTUSEMOD (optional/obsolete): list of project mods needed by this mod and linked with
### TLINKLIB: list of libs/mods needed by the test library of this mod and linked with. The format is $(APPNAME)_$(MODNAME) for module or $(APPNAME) for entire lib.
### INCLUDE_TESTMODS: list of libs/mods needed by test library of this mod but not linked with. The format is $(APPNAME)_$(MODNAME) for module or $(APPNAME) for entire lib.
###

# the includes modules directly associated to this module
DEFAULT_ABS_INCLUDE_MODS:=$(patsubst %,$(APPNAME)_%,$(USEMOD) $(USELKMOD)) $(LINKLIB) $(INCLUDE_MODS)
DEFAULT_ABS_INCLUDE_TESTMODS:=$(patsubst %,$(APPNAME)_%,$(TESTUSEMOD)) $(TLINKLIB) $(INCLUDE_TESTMODS)

# definition of variables used to find the path to modules trdir.
MODULES_DEPS:=$(patsubst ../%/module.cfg,%,$(wildcard ../*/module.cfg))
PROJECT_MODS:=$(patsubst %,$(APPNAME)_%,$(MODULES_DEPS))
$(foreach mod,$(MODULES_DEPS),$(eval _module_$(APPNAME)_$(mod)_dir=$(TRDIR)))

# ALL_NEEDED_MODS contains all the project modules needed by this module.
ALL_NEEDED_MODS:=$(sort $(patsubst $(APPNAME)_%,%,$(filter $(PROJECT_MODS),$(DEFAULT_ABS_INCLUDE_MODS) $(DEFAULT_ABS_INCLUDE_TESTMODS))))

generateAppModsNeeds:
	@mkdir -p $(OBJDIR)
	@echo $(patsubst %,mod.%,$(ALL_NEEDED_MODS)) > $(OBJDIR)/moddeps.needs
