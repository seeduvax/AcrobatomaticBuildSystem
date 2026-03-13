## 
## --------------------------------------------------------------------
## VSCode utilities.
## --------------------------------------------------------------------
## Targets:
##  - vscodeconfig: Generate the c_cpp_properties.json for vscode to correctly add include paths.

VSCODE_CPP_CONFIG=$(PRJROOT)/.vscode/c_cpp_properties.json

vscodeconfig: $(VSCODE_CPP_CONFIG)

MODULES_WITH_INCLUDES=$(foreach mod,$(MODULES),$(if $(wildcard $(mod)/include),$(mod)))
.PHONY: $(VSCODE_CPP_CONFIG)
$(VSCODE_CPP_CONFIG): app.cfg
	@$(ABS_PRINT_info) "Generation of $@"
	@mkdir -p $(@D)
	@printf '{\n' > $@.tmp
	@printf '"configurations": [\n' >> $@.tmp
	@printf '    {\n' >> $@.tmp
	@printf '        "name": "Linux",\n' >> $@.tmp
	@printf '        "includePath": [\n' >> $@.tmp
	@$(foreach mod,$(MODULES_WITH_INCLUDES),printf '            "$${workspaceFolder}/$(mod)/include/",\n' >> $@.tmp;)
	@printf '            "$${workspaceFolder}/$(patsubst $(PRJROOT)/%,%,$(TRDIR))/include/",\n' >> $@.tmp
	@$(foreach path,$(patsubst $(PRJROOT)/%,%,$(wildcard $(EXTLIBDIR)/*/*/include) $(wildcard $(NA_EXTLIBDIR)/*/*/include) $(wildcard $(NDEXTLIBDIR)/*/*/include) $(wildcard $(NDNA_EXTLIBDIR)/*/*/include)),printf '            "$${workspaceFolder}/$(path)",\n' >> $@.tmp;)
	@printf '            "$(ABSROOT)/core/include/"\n' >> $@.tmp
	@printf '        ],\n' >> $@.tmp
	@$(if $(filter true,$(DISABLE_COMPILE_COMMANDS)),,printf '        "compileCommands": "$${workspaceFolder}/compile_commands.json"\n' >> $@.tmp)
	@printf '    }\n' >> $@.tmp
	@printf ']}' >> $@.tmp
	@mv $@.tmp $@