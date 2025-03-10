
# WARNING : include module-crules-vars.mk before including this file !

# ---------------------------------------------------------------------
# standard C/C++ rules
# Note:
# The sed script postprocessing gcc generated dependencies ensure that
# a removed and no more used header will not make the compilation fail.
# Check http://mad-scientist.net/make/autodep.html#norule for more
# details.
## 
## ---------------------------------------------------------------------
## C/C++ build options
## ---------------------------------------------------------------------
##  - STATIC_LIB=true|false, when true, generate static libraries, and link
##    statically. Default value is false.
##  - DYNAMIC_LIB=true|false, when true, generate dynamic libraries, and link
##    dynamically. Default value is true.
##    When both STATIC_LIB and DYNAMIC_LIB are true, builds both statict and
##    dynamic libraries but link executables dynamically only.
##  - NO_VINFO=true|false, when true, do not generate and link the source file 
##    for the target binary embedded identifiers string. Default is false. 
##    activate this option in case of small memory footprint or reproductible
##    builds requirements (because the string might be long and include build
##    context info such as build host and build date).
##  - ACTIVATE_SANITIZER: activate the compiler sanitizer
##    - true: address sanitizer (leak memory detector)
##    - thread: thread sanitizer (data race detector). Incompatible with address sanitizer
##    To disable the leak detection on sources compiled with address sanitizer, use the environment variable asan_options=detect_leaks=0
##    /!\ Must not be used to compile production binaries.
##  - CROSS_ARCH: Architecture for cross compilation. (ex: aarch64, mingw, ...)
##  - ARCH_EXECUTOR: the executable used to execute cross-compiled binaries
##    Ex: on a aarch64, can be qemu-aarch64-static
##  - CROSS_PREFIX: Prefix for cross-compilation compilers
##    Ex: on a aarch64, can be aarch-linux-gnu-
##  - CFLAGS: CFLAGS for C/C++ compilations.
##  - CXXFLAGS: CXXFLAGS for C++ compilations.
##  - LDFLAGS: LDFLAGS for C/C++ linkage
##  - DEFINES: The defines to add to CFLAGS variables.
##      Each define will be -D$(define) in CFLAGS
##  - DISABLE_SRC: List of files in src directory to not compile

include $(ABSROOT)/core/module-cheaders.mk

# object files : one for each c and cpp file.
COBJS+=$(patsubst src/%.c,$(OBJDIR)/%.o,$(filter-out $(patsubst %,src/%,$(DISABLE_SRC)),$(filter %.c,$(SRCFILES))))
#COBJS+=$(patsubst src/%.c,$(OBJDIR)/%.o,$(filter-out $(patsubst %,$(EXT_SRC_DIR)/%,$(DISABLE_SRC)),$(filter %.c,$(EXTSRCFILES))))
CPPOBJS+=$(patsubst src/%.cpp,$(OBJDIR)/%.o,$(filter-out $(patsubst %,src/%,$(DISABLE_SRC)),$(filter %.cpp,$(SRCFILES))))
CPPOBJS+=$(patsubst $(EXT_SRC_DIR)/%.cpp,$(OBJDIR)/%.o,$(filter-out $(patsubst %,$(EXT_SRC_DIR)/%,$(DISABLE_SRC)),$(filter %.cpp,$(EXTSRCFILES))))
RESSRC:=$(filter src/embedded_lua/%.lua src/res/%,$(SRCFILES))
GENSRC+=$(patsubst src/%,$(OBJDIR)/%.c,$(RESSRC))
GENOBJS+=$(patsubst %.c,%.o,$(filter %.c,$(GENSRC)))
GENOBJS+=$(patsubst %.cpp,%.o,$(filter %.cpp,$(GENSRC)))
GENOBJS+=$(patsubst %.adb,%.o,$(filter %.adb,$(GENSRC)))

# All objs: C et CCP files + generated
OBJS+=$(COBJS) $(CPPOBJS) $(GENOBJS) $(OBJDIR)/vinfo.o
# remove duplicates to avoid multiple definitions errors.
OBJS:=$(sort $(OBJS))
OBJS_NO_VINFO:=$(filter-out $(OBJDIR)/vinfo.o,$(OBJS))

RES_HEADER=$(TRDIR)/include/$(APPNAME)/$(MODNAME)/res.h

# includes dependencies
-include $(patsubst %.o,%.o.d,$(OBJS))


# ---------------------------------------------------------------------
# Default target : build target file
# ---------------------------------------------------------------------
C_RULES_ALL_TARGETS+=$(TARGETFILE) $(TARGETARCHIVE) $(PUBLISHED_HEADERS)

# ---------------------------------------------------------------------
# Main transformation rules
# ---------------------------------------------------------------------
# C file compilation
$(OBJDIR)/%.o: src/%.c
	$(cc-command)

# generated C file compilation
$(OBJDIR)/%.o: $(OBJDIR)/%.c
	$(cc-command)

# external C file compilation
$(OBJDIR)/%.o: $(EXT_SRC_DIR)/%.c
	$(cc-command)

# from idl generated cpp files compilation
$(OBJDIR)/idl/%.o: $(OBJDIR)/idl/%.cpp 
	$(CPPC) $(CFLAGS) -c $< -o $@

# generated cpp files compilation
$(OBJDIR)/%.o: $(OBJDIR)/%.cpp
	$(cxx-command)

# external cpp files compilation
$(OBJDIR)/%.o: $(EXT_SRC_DIR)/%.cpp
	$(cxx-command)

# cpp files compilation
$(OBJDIR)/%.o: src/%.cpp
	$(cxx-command)

# link target from objects
ifeq ($(MODTYPE),library)
ifneq ($(TARGETFILE),)
ifneq ($(NO_VINFO),)
ifeq ($(strip $(OBJS_NO_VINFO)),)
$(TARGETFILE): $(OBJS_NO_VINFO)
	@echo nothing to do
else 
$(TARGETFILE): $(OBJS_NO_VINFO)
	$(ld-command-lib)
endif
else
$(TARGETFILE): $(OBJS)
	$(ld-command-lib)
endif
endif
ifneq ($(TARGETARCHIVE),)
ifeq ($(strip $(OBJS_NO_VINFO)),)
$(TARGETARCHIVE): $(OBJS_NO_VINFO)
	@echo nothing to do
else
$(TARGETARCHIVE): $(OBJS_NO_VINFO)
	$(ar-command-lib)
endif
endif
else
ifneq ($(NO_VINFO),)
$(TARGETFILE): $(OBJS_NO_VINFO)
	$(ld-command-exe)
else
$(TARGETFILE): $(OBJS)
	$(ld-command-exe)
endif
endif

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
	@$(ABS_PRINT_info) "Generating Empty Resource header..."
	@mkdir -p `dirname $(RES_HEADER)` 
	@printf "/* Generated resource constant header, do not edit */\n\
#ifndef __$(APPNAME)_$(MODNAME)_res_h__\n\
# define __$(APPNAME)_$(MODNAME)_res_h__\n\
# ifdef __cplusplus\n\
extern \"C\" {\n\
# endif\n" > $@
	@for src in $(RESSRC) ; do \
	varprefix=`echo $$src | sed -e 's/[\./\-]/_/g' -e 's/^src_/$(APPNAME)_$(MODNAME)_/g'` ; \
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
	@echo "#include \"$(APPNAME)/$(MODNAME)/res.h\"" > $@
	@xxd -i $< | sed -e "s/src_/$(APPNAME)_$(MODNAME)_/g" >> $@


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
RUNTIME_PROLOG?=:
RUNTIME_EPILOG?=:
ifeq ($(MODTYPE),library)
# don't run a library !
run:: all
	$(ABS_PRINT_error) "won't run a library !"

debug:: all
	$(ABS_PRINT_error) "won't debug a library !"

else
# run application
# TODO cygwin compat
run:: all
	@$(ABS_PRINT_info) "Starting $(TARGETFILE) $(RUNARGS)"
	@$(RUNTIME_PROLOG)
	@PATH=$(RUNPATH) LD_LIBRARY_PATH=$(LDLIBP) $(RUNTIME_ENV) $(ARCH_EXECUTOR) $(TARGETFILE) $(RUNARGS) \
      || $(ABS_PRINT_error) "Run failed: $(TARGETFILE) $(RUNARGS)"
	@$(RUNTIME_EPILOG)

GDBCMD:=$(BUILDROOT)/gdb-$(MODNAME)

.PHONY: debugcmd
gdbcmd: $(TARGETFILE)
	@$(ABS_PRINT_info) "Generating gdb test script $(GDBCMD)"
	@mkdir -p $(BUILDROOT)
	@echo 'set environment LD_LIBRARY_PATH=$(TLDLIBP)' > $(GDBCMD)
	@echo 'set args $(RUNARGS)' >> $(GDBCMD)
	@echo 'file $(TARGETFILE)' >> $(GDBCMD)
	@printf "define runapp\nrun\nend\n" >> $(GDBCMD)


# run application with gdb
# TODO cygwin compat
debug:: $(TARGETFILE) gdbcmd
	@PATH=$(RUNPATH) $(RUNTIME_ENV) gdb -x $(GDBCMD)

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
