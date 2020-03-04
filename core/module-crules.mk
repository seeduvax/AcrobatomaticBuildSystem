
# WARNING : include module-crules-vars.mk before including this file !

# ---------------------------------------------------------------------
# standard C/C++ rules
# Note:
# The sed script postprocessing gcc generated dependencies ensure that
# a removed and no more used header will not make the compilation fail.
# Check http://mad-scientist.net/make/autodep.html#norule for more
# details.
# ---------------------------------------------------------------------
include $(ABSROOT)/core/module-cheaders.mk

# object files : one for each c and cpp file.
COBJS+=$(patsubst src/%.c,$(OBJDIR)/%.o,$(filter-out $(patsubst %,src/%,$(DISABLE_SRC)),$(filter %.c,$(SRCFILES))))
CPPOBJS+=$(patsubst src/%.cpp,$(OBJDIR)/%.o,$(filter-out $(patsubst %,src/%,$(DISABLE_SRC)),$(filter %.cpp,$(SRCFILES))))
RESSRC:=$(filter src/embedded_lua/%.lua src/res/%,$(SRCFILES))
GENSRC+=$(patsubst src/%,$(OBJDIR)/%.c,$(RESSRC))
GENOBJS+=$(patsubst %.c,%.o,$(GENSRC))

# All objs: C et CCP files + generated
OBJS+=$(COBJS) $(CPPOBJS) $(GENOBJS) $(OBJDIR)/vinfo.o
# remove duplicates to avoid multiple definitions errors.
OBJS:=$(sort $(OBJS))

RES_HEADER=$(TRDIR)/include/$(APPNAME)/$(MODNAME)/res.h

# includes dependencies
-include $(patsubst %.o,%.o.d,$(OBJS))


# ---------------------------------------------------------------------
# Default target : build target file
# ---------------------------------------------------------------------
C_RULES_ALL_TARGETS+=$(TARGETFILE) $(PUBLISHED_HEADERS)

# ---------------------------------------------------------------------
# Main transformation rules
# ---------------------------------------------------------------------
# C file compilation
$(OBJDIR)/%.o: src/%.c
	$(cc-command)

# generated C file compilation
$(OBJDIR)/%.o: $(OBJDIR)/%.c
	$(cc-command)

# from idl generated cpp files compilation
$(OBJDIR)/idl/%.o: $(OBJDIR)/idl/%.cpp 
	$(CPPC) $(CFLAGS) -c $< -o $@

# generated cpp files compilation
$(OBJDIR)/%.o: $(OBJDIR)/%.cpp
	$(cxx-command)

# cpp files compilation
$(OBJDIR)/%.o: src/%.cpp
	$(cxx-command)

# Ada files compilation
$(OBJDIR)/%.o: src/%.adb
	@$(ABS_PRINT_info) "Compiling $< ..."
	@mkdir -p $(@D)
	@echo `date --rfc-3339 s`"> $(AFAC) $(ADAFLAGS) -c $< -D $(@D)" >> $(TRDIR)/build.log
	@$(ADAC) $(CFLAGS) -c $< -D $(@D) || ( $(ABS_PRINT_error) "Failed: ADAFLAGS=$(ADAFLAGS)" ; exit 1 )

# link target from objects
$(TARGETFILE): $(OBJS)
	$(ld-command)

# vinfo file generated from make macro value.
# vinfo must be regenerated each time a source file change, since it
# may come from any update of the workspace from the repository.
VINFO:=$(OBJDIR)/vinfo.cpp

ifeq ($(APPNAME),$(MODNAME))
define absVInfoShortAlias
	@echo "const char * _$(APPNAME)_vinfo=_$(APPNAME)_$(MODNAME)_vinfo;" >> $@
	@echo "const char * _$(APPNAME)_version=_$(APPNAME)_$(MODNAME)_version;" >> $@
endef
endif

$(VINFO): module.cfg $(PRJROOT)/app.cfg $(SRCFILES)
	@$(ABS_PRINT_info) "Generating vinfo for module $(MODNAME) ..."
	@mkdir -p $(OBJDIR)
	@echo "const char * _$(APPNAME)_$(MODNAME)_vinfo=" > $@
	@echo "	\"\$$Attr: app.name=$(APPNAME) $$ \"" >> $@
	@echo "	\"\$$Attr: app.version=$(VERSION) $$ \"" >> $@
	@echo "	\"\$$Attr: app.revision=$(REVISION) $$ \"" >> $@
	@echo "	\"\$$Attr: app.file=$(TARGET) $$ \"" >> $@
	@echo "	\"\$$Attr: company=$(COMPANY) $$ \"" >> $@
	@echo "	\"\$$Attr: copyright=$(COPYRIGHT) $$ \"" >> $@
	@echo "	\"\$$Attr: build.mode=$(MODE) $$ \"" >> $@
	@echo "	\"\$$Attr: build.opts=$(DEFINES) $$ \"" >> $@
	@echo "	\"\$$Attr: build.date="`date`" $$ \"" >> $@
	@echo "	\"\$$Attr: build.host="`hostname`" $$ \"" >> $@
	@echo "	\"\$$Attr: build.user=$(USER) $$ \"" >> $@
	@echo "	\"\$$Attr: build.id=$(BUILDNUM) $$ \";" >> $@
	@echo "const char * _$(APPNAME)_$(MODNAME)_version=\"$(VERSION)\";" >> $@
	$(call absVInfoShortAlias)
	$(call absVInfoExtra)

ifneq ($(GENSRC),)
# dependencies management.
$(GENSRC):
endif

$(RES_HEADER):
	@$(ABS_PRINT_info) "Generating Empty Ressource header..."
	@mkdir -p `dirname $(RES_HEADER)` 
	@printf "/* Generated resource constant header, do not edit */\n\
#ifndef __$(APPNAME)_$(MODNAME)_res_h__\n\
# define __$(APPNAME)_$(MODNAME)_res_h__\n\
# ifdef __cplusplus\n\
extern \"C\" {\n\
# endif\n" > $@
	@for src in $(RESSRC) ; do \
	varprefix=`echo $$src | sed -e 's/[\./\-]/_/g' | sed -e 's/^src_/$(APPNAME)_$(MODNAME)_/g'` ; \
	echo 'extern unsigned char '$$varprefix'[];' >> $@ ; \
	echo 'extern unsigned int '$$varprefix'_len;' >> $@ ; \
	done
	@printf "# ifdef __cplusplus\n\
}\n\
# endif\n\
#endif" >> $@ 

# data file embedding using xxd
$(OBJDIR)/%.c: src/% $(RES_HEADER)
	@$(ABS_PRINT_info) "Generating inline constant buffer from $<..."
	@mkdir -p $(@D)
	@echo "#include \"$(RES_HEADER)\"" > $@
	@xxd -i $< | sed -e "s/src_/$(APPNAME)_$(MODNAME)_/g"  >> $@


# relative path (used by edebug and edebugtest targets for more readability)
RELPRJROOT=$(if $(shell which realpath 2>/dev/null),$(shell realpath --relative-to="$$PWD" "$(PRJROOT)"),$(shell python -c "import os.path; print os.path.relpath('$(PRJROOT)')"))
define relativePath
$(patsubst $(PRJROOT)/%,$(RELPRJROOT)/%,$(1))
endef

# ---------------------------------------------------------------------
# Extra dependencies
# ---------------------------------------------------------------------
# Generating object files need dependant modules to be already built
# and external libraries to be installed in build area.

$(OBJS): $(patsubst %,$(TRDIR)/include/$(APPNAME)/%,$(USELKMOD))

$(COBJS) $(CPPOBJS): $(GENSRC)



# ---------------------------------------------------------------------
# Run & debug rules
# ---------------------------------------------------------------------
ifeq ($(MODTYPE),library)
# don't run a library !
run:: all
	$(ABS_PRINT_error) "won't run a library !"

debug:: all
	$(ABS_PRINT_error) "won't debug a library !"

else
# run application
run:: all
	@$(ABS_PRINT_info) "Starting $(TARGETFILE) $(RUNARGS)"
	@PATH=$(RUNPATH) LD_LIBRARY_PATH=$(LDLIBP) $(TARGETFILE) $(RUNARGS)

# run application with gdb
debug:: $(TARGETFILE)
	@printf "define runapp\nrun $(RUNARGS)\nend\n" > cmd.gdb
	@printf "\e[1;4mUse runapp command to launch app from gdb\n\e[37;37;0m"
	@PATH=$(RUNPATH) LD_LIBRARY_PATH=$(LDLIBP) gdb $(TARGETFILE) -x cmd.gdb
	@rm cmd.gdb

# print eclipse setup
.PHONY:	edebug
edebug:
	@echo "**** Eclipse debugger setup : ****"
	@echo
	@printf "Application:\t\t"
	@echo "$(patsubst $(PRJROOT)/%,%,$(TARGETFILE))"
	@printf "Arguments:\t\t"
	@echo $(RUNARGS)
	@echo
	@echo "* Environment (replace native) :"
	@echo
	@printf "PATH\t"
	@echo "$(subst $(eval) ,:,$(foreach entry,$(subst :, ,$(RUNPATH)),$(patsubst $(PRJROOT)/%,%,$(entry))))"
	@printf "LD_LIBRARY_PATH\t"
	@echo "$(subst $(eval) ,:,$(foreach entry,$(subst :, ,$(LDLIBP)),$(patsubst $(PRJROOT)/%,%,$(entry))))"
endif

clean-crule:
	@$(ABS_PRINT_info) "Removing generated resource header files..."
	@rm -rf $(RES_HEADER) 

clean:: clean-crule

all-impl:: $(C_RULES_ALL_TARGETS) etc
