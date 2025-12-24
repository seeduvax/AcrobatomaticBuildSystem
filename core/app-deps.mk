# This makefile need some variables defined in app-dist.mk and common-extlib.mk
## 
## ------------------------------------------------------------------------
## Dependencies Information
## ------------------------------------------------------------------------
## Targets:
##  - checkdep: show currently defined dependencies (full graph including
##    dependencies of dependencies).
##  - checkdeplist: show currently defined dependencies in a list
##  - checkmodsdep: show currently defined modules dependencies (full graph including
##    dependencies of dependencies of modules).
##  - checkdeptest: show currently defined dependencies including test (full graph including
##    dependencies of dependencies).
##  
## Variables:
##  - DEPS_SHOW_ONLY_NEEDED=[true/false]: indicates if only needed libraries must be shown in 
##    graph or list (default: false).
##
ifneq ($(USELIB),)

DEPS_SHOW_ONLY_NEEDED?=false

DEPS_NEEDED_LIBS=$(foreach lib,$(INCLUDE_EXT_LIBS),$(lib)|$(_app_$(lib)_version)) \
			 	 $(foreach mod,$(INCLUDE_EXT_MODULES),$(_module_$(mod)_app)|$(_app_$(_module_$(mod)_app)_version))

DEPS_TO_SHOW=$(sort $(if $(filter true,$(DEPS_SHOW_ONLY_NEEDED)),$(DEPS_NEEDED_LIBS),$(ALLUSELIB)))

#
# Get dependencies of given lib
# To get all dependencies, need to get the uselib of each module of a library
# $1 the lib without version
#
define getAllLibsDependencies
$(sort $(_app_$1_uselib) $(foreach mod,$(_app_$1_modules),$(_module_$1_$(mod)_uselib)))
endef

#
# Get dependencies of given lib
# $1 the lib without version
#
define getLibsDependencies
$(if $(filter true,$(DEPS_SHOW_ONLY_NEEDED)),$(filter $(subst |,-,$(DEPS_TO_SHOW)),$(subst |,-,$(call getAllLibsDependencies,$1))),$(subst |,-,$(call getAllLibsDependencies,$1)))
endef

#
# Filter of dependencies depends less version separator.
# $1 filter
# $2 list
#
define filterDependencies
$(foreach element,$2,$(if $(filter $(subst |,-,$(element)),$(subst |,-,$1)),$(element)))
endef

define generateCheckDep
	@$(ABS_PRINT_info) "Generating project dependency graph."
	@printf 'digraph deps {\ngraph [rankdir="LR",ranksep=1];\nnode [width=2, shape=box, style="rounded"];\n' > $@
	@printf ' $(foreach dep,$(subst |,-,$(sort $1)),"$(APPNAME)-$(VERSION)"->"$(dep)";\n)' >> $@
	@$(foreach lib,$(DEPS_TO_SHOW),$(foreach dep,$(call getLibsDependencies,$(call getLibNameFromVersioned,$(lib))),echo "\"$(subst |,-,$(lib))\"->\"$(dep)\"$(if $(filter $(dep),$(DEPS_BAD_LIB)),[color=\"red\"])" >> $@;))
	@$(foreach lib,$(DEPS_BAD_LIB),echo "\"$(lib)\"[color=\"red\"]" >> $@;)
	@echo "}" >> $@
	@sed -i -e 's/d";$$/d"\[color="orange"\];/g' $@
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
	@$(call generateCheckDep,$(call filterDependencies,$(DEPS_TO_SHOW),$(sort $(_modules_$(APPNAME)_uselib))))
	
$(BUILDROOT)/$(APPNAME)_testdeps.dot: $(PRJROOT)/app.cfg
	@$(call generateCheckDep,$(call filterDependencies,$(DEPS_TO_SHOW),$(sort $(_modules_$(APPNAME)_uselib)) $(_modules_$(APPNAME)_nduselib)))

$(BUILDROOT)/$(APPNAME)_modsdeps.dot: $(PRJROOT)/app.cfg
	@$(call generateCheckModDep,$(MODULES))

checkdep: $(BUILDROOT)/$(APPNAME)_deps.dot
	@$(call showCheckDep)

checkmodsdep: $(BUILDROOT)/$(APPNAME)_modsdeps.dot
	@$(call showCheckDep)

checkdeptest: $(BUILDROOT)/$(APPNAME)_testdeps.dot
	@$(call showCheckDep)

checkdeplist: $(PRJROOT)/app.cfg
	@$(foreach lib,$(sort $(DEPS_TO_SHOW)),$(if $(_app_$(call getLibNameFromVersioned,$(lib))_version),echo "$(lib)";))

else #ifneq ($(USELIB),)
checkdep:
	@$(ABS_PRINT_info) "No dependencies set in USELIB project parameter."

checkdeptest:
	@$(ABS_PRINT_info) "No dependencies set in USELIB project parameter."
endif #ifneq ($(USELIB),)