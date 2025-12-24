
## Targets:
##  - checkdep: show currently defined dependencies (full graph including
##    dependencies of dependencies).
##  - checkmodsdep: show currently defined modules dependencies (full graph including
##    dependencies of dependencies of modules).
##  - checkdeptest: show currently defined dependencies including test (full graph including
##    dependencies of dependencies).
ifneq ($(USELIB),)
define generateCheckDep
	@$(ABS_PRINT_info) "Generating project dependency graph."
	@printf 'digraph deps {\ngraph [rankdir="LR",ranksep=1];\nnode [width=2, shape=box, style="rounded"];\n' > $@
	@printf ' $(foreach dep,$(subst |,-,$(sort $1)),"$(APPNAME)-$(VERSION)"->"$(dep)";\n)' | sed -e 's/d";$$/d"\[color="orange"\];/g'>> $@
	@printf ' $(foreach dep,$(subst |,-,$(ADDEDDEPLIST)),$(dep);\n)' | sort -u | sed -e 's/d";$$/d"\[color="orange"\];/g'>> $@
	@echo "}" >> $@
	@dot -Tpng $@ > $@.png
endef

define getModsDepsForGraph
$(if $(filter $1,$2),,$(foreach depend,$(_module_$1_depends),"$1"->"$(depend)";\n $(call getModsDepsForGraph,$(depend),$2 $1)))
endef
define generateCheckModDep
	@$(ABS_PRINT_info) "Generating modules dependency graph."
	@printf 'digraph deps {\ngraph [rankdir="LR",ranksep=1];\nnode [width=2, shape=box, style="rounded"];\n' > $@
	@printf ' $(sort $(foreach dep,$(subst |,-,$1),$(call getModsDepsForGraph,$(APPNAME)_$(dep))))' | sort -u>> $@
	@echo "}" >> $@
	@dot -Tpng $@ > $@.png
endef

define showCheckDep
	@$(ABS_PRINT_info) "Launching image viewer to display the generated dependency graph $<.png."
	@$(ABS_PRINT_info) "Close image viewer to continue or hit Ctrl-C to stop here."
	@xdot $< 2>/dev/null || eog $<.png 2>/dev/null || xdg-open $<.png 2>/dev/null || $(ABS_PRINT_error) "No image viewer found (expected one of: xdot, eog, xdg-open)"
endef

$(BUILDROOT)/$(APPNAME)_deps.dot: $(PRJROOT)/app.cfg
	@$(call generateCheckDep,$(USELIB))
	
$(BUILDROOT)/$(APPNAME)_testdeps.dot: $(PRJROOT)/app.cfg
	@$(call generateCheckDep,$(USELIB) $(NDUSELIB))

$(BUILDROOT)/$(APPNAME)_modsdeps.dot: $(PRJROOT)/app.cfg
	@$(call generateCheckModDep,$(MODULES))

checkdep: $(BUILDROOT)/$(APPNAME)_deps.dot
	@$(call showCheckDep)

checkmodsdep: $(BUILDROOT)/$(APPNAME)_modsdeps.dot
	@$(call showCheckDep)

checkdeptest: $(BUILDROOT)/$(APPNAME)_testdeps.dot
	@$(call showCheckDep)

else #ifneq ($(USELIB),)
checkdep:
	@$(ABS_PRINT_info) "No dependencies set in USELIB project parameter."

checkdeptest:
	@$(ABS_PRINT_info) "No dependencies set in USELIB project parameter."
endif #ifneq ($(USELIB),)