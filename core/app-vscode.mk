## 
## --------------------------------------------------------------------
## VSCode utilities.
## --------------------------------------------------------------------
## Targets:
##  - vscodeconfig: Generate the c_cpp_properties.json for vscode to correctly add include paths.

VSCODE_CPP_CONFIG=$(PRJROOT)/.vscode/c_cpp_properties.json

vscodeconfig: $(VSCODE_CPP_CONFIG)

MODULES_WITH_INCLUDES=$(foreach mod,$(MODULES),$(if $(wildcard $(mod)/include),$(mod)))
VSCODE_PATHS_FROM_EXTLIBS=$(wildcard $(EXTLIBDIR)/*/*/include) $(wildcard $(NA_EXTLIBDIR)/*/*/include) $(wildcard $(NDEXTLIBDIR)/*/*/include) $(wildcard $(NDNA_EXTLIBDIR)/*/*/include)
# USE CFLAGS et CXXFLAGS for includes defined in external libs
VSCODE_PATHS_FROM_CFLAGS=$(foreach path,$(sort $(patsubst -I%,%,$(filter -I%,$(CXXFLAGS) $(CFLAGS)))),$(if $(wildcard $(path)),$(path)))

VSCODE_ALL_INCLUDES=$(patsubst %,$(PRJROOT)/%/include/,$(MODULES_WITH_INCLUDES))
VSCODE_ALL_INCLUDES+=$(TRDIR)/include/
VSCODE_ALL_INCLUDES+=$(VSCODE_PATHS_FROM_EXTLIBS)
VSCODE_ALL_INCLUDES+=$(VSCODE_PATHS_FROM_CFLAGS)

VSCODE_ALL_INCLUDES_REL=$(patsubst $(PRJROOT)/%,%,$(foreach path,$(VSCODE_ALL_INCLUDES),$(if $(wildcard $(path)),$(path))))

.PHONY: $(VSCODE_CPP_CONFIG)
$(VSCODE_CPP_CONFIG): app.cfg
	@$(ABS_PRINT_info) "Generation of $@"
	@mkdir -p $(@D)
	@printf '{\n' > $@.tmp
	@printf '"configurations": [\n' >> $@.tmp
	@printf '    {\n' >> $@.tmp
	@printf '        "name": "Linux",\n' >> $@.tmp
	@printf '        "includePath": [\n' >> $@.tmp
	@$(foreach path,$(sort $(VSCODE_ALL_INCLUDES_REL)),printf '            "$${workspaceFolder}/$(path)",\n' >> $@.tmp;)
	@printf '            "$(ABSROOT)/core/include/"\n' >> $@.tmp
	@printf '        ],\n' >> $@.tmp
	@$(if $(filter true,$(DISABLE_COMPILE_COMMANDS)),,printf '        "compileCommands": "$${workspaceFolder}/compile_commands.json"\n' >> $@.tmp)
	@printf '    }\n' >> $@.tmp
	@printf ']}' >> $@.tmp
	@mv $@.tmp $@