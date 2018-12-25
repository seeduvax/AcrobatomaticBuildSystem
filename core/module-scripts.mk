## --------------------------------------------------------------------
## Script management
## CAUTION: Deprecated feature, consider to move your scripts in a 
## dedicated fileset module.
## --------------------------------------------------------------------
## 
## Variables:
##   - SRC_SCRIPTS: list of source files to be handled as scripts.
##      Defaulty computed by searching from src dir all files starting with 
##      the shebang ("#!"). Those files are copied to the target bin directory.
SRC_SCRIPTS:=$(shell find src/ -type f | grep -v '/.svn/' | xargs grep -ln '^\#!')

OBJ_SCRIPTS:=$(patsubst src/%,$(OBJDIR)/.sh/%,$(SRC_SCRIPTS))

all-impl:: $(OBJ_SCRIPTS) etc	

# use pseudo target in $(OBJDIR)/.sh to avoid any rules collision risk without
# having to play with particular file name extension for scripts.
$(OBJDIR)/.sh/%: src/%
	@$(ABS_PRINT_info) "Publishing script $^..."
	@$(ABS_PRINT_warning) "Deprecated ABS feature, consider to create a fileset module to store your application's scripts."
	@mkdir -p $(@D)
	@touch $@
	@mkdir -p $(TRDIR)/bin
	@cp $^ $(TRDIR)/bin
	@chmod +x $(TRDIR)/bin/$(@F)

## 
## Targets:
.PHONY: sh
##  - sh SH=<script>: run script using application context
sh: all
	@$(ABS_PRINT_info) "Launching $(SH)..."
	@cd $(TRDIR) ; LD_LIBRARY_PATH=$(LDLIBP) bin/$(SH) $(RUNRARGS)


