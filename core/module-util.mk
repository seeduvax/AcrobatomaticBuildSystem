## 
## --------------------------------------------------------------------
## Extra utilities
## 
## Targets:
ifeq ($(APPNAME),$(MODNAME))
	NAMESPACE_BEGIN=namespace $(APPNAME) {
	NAMESPACE_END=} // namespace $(APPNAME)
	INC_PATH=$(APPNAME)
	INC_GUARDPREFIX=__$(APPNAME)
	PACKAGE=$(DOMAIN).$(APPNAME)
else
	NAMESPACE_BEGIN=namespace $(APPNAME) {\n\tnamespace $(MODNAME) {
	NAMESPACE_END=}} // namespace $(APPNAME)::$(MODNAME)
	INC_PATH=$(APPNAME)/$(MODNAME)
	INC_GUARDPREFIX=__$(APPNAME)_$(MODNAME)
	PACKAGE=$(DOMAIN).$(APPNAME).$(MODNAME)
endif

##  - newclass <class name>: create source code file for new class from 
##     template
ifeq ($(word 1,$(MAKECMDGOALS)),newclass)
CLASSNAME=$(word 2,$(MAKECMDGOALS))$(C)

.PHONY: newclass
ifeq ($(MODTYPE),jar)
newclass:
	@$(ABS_PRINT_info) "generating class template for $(PACKAGE).$(CLASSNAME)"
	@mkdir -p `dirname src/$(subst .,/,$(PACKAGE).$(CLASSNAME))`
	@printf "/*\n\
 * @file $(CLASSNAME).java\n\
 *\n\
 * Copyright %d $(COMPANY). All rights reserved.\n\
 * Use is subject to license terms.\n\
 *\n\
 * \$$Id$$\n\
 * \$$Date$$\n\
 */\n\
package $(PACKAGE);\n\
\n\
/**\n\
 *\n\
 */\n\
public class $(CLASSNAME) {\n\
}\n\
" `date +%Y`> src/$(subst .,/,$(PACKAGE).$(CLASSNAME)).java

else ifeq ($(MODTYPE),python)
newclass:
	@$(ABS_PRINT_info) "generating python modulescript template $(APPNAME).$(MODNAME).$(CLASSNAME)"
	@mkdir -p src/$(INC_PATH)
	@test -f src/$(INC_PATH)/__init__.py || printf "# -*-coding:Utf-8 -*\n\
# @file __init__.py\n\
#\n\
# Copyright %d $(COMPANY). All rights reserved.\n\
# Use is subject to license terms.\n\
# \n\
# \$$Id$$\n\
# \$$Date$$\n\
# \n\
# module import entry point \n\
# for subpackage $(APPNAME).$(MODNAME)\n\
print 'importing $(APPNAME).$(MODNAME) ...'\n\
\n\
print 'importing $(APPNAME).$(MODNAME) ... OK'\n\
\n\
" `date +%Y` > src/$(INC_PATH)/__init__.py
	@test -f src/$(INC_PATH)/__main__.py || printf "# -*-coding:Utf-8 -*\n\
# @file __main__.py\n\
#\n\
# Copyright %d $(COMPANY). All rights reserved.\n\
# Use is subject to license terms.\n\
# \n\
# \$$Id$$\n\
# \$$Date$$\n\
# \n\
# module call entry point \n\
# for subpackage $(APPNAME).$(MODNAME)\n\
\n\
print 'running $(APPNAME).$(MODNAME) ...'\n\
import $(APPNAME).$(MODNAME)\n\
print 'running $(APPNAME).$(MODNAME) ... OK'\n\
\n\
" `date +%Y` > src/$(INC_PATH)/__main__.py
	@test -f src/$(INC_PATH)/$(CLASSNAME).py || printf "# -*-coding:Utf-8 -*\n\
# @file $(CLASSNAME).py\n\
#\n\
# Copyright %d $(COMPANY). All rights reserved.\n\
# Use is subject to license terms.\n\
# \n\
# \$$Id$$\n\
# \$$Date$$\n\
# \n\
# module hierarchy:\n\
# $(APPNAME).$(MODNAME).$(CLASSNAME)\n\
\n\
" `date +%Y` > src/$(INC_PATH)/$(CLASSNAME).py

else
newclass:
	@$(ABS_PRINT_info) "generating class template for $(APPNAME)::$(MODNAME)::$(CLASSNAME)"
	@mkdir -p include/$(INC_PATH)
	@test -f include/$(INC_PATH)/$(CLASSNAME).hpp || printf "/*\n\
 * @file $(CLASSNAME).hpp\n\
 *\n\
 * Copyright %d $(COMPANY). All rights reserved.\n\
 * Use is subject to license terms.\n\
 *\n\
 * \$$Id$$\n\
 * \$$Date$$\n\
 */\n\
#ifndef $(INC_GUARDPREFIX)_$(CLASSNAME)_HPP__\n\
#define $(INC_GUARDPREFIX)_$(CLASSNAME)_HPP__\n\
\n\
$(NAMESPACE_BEGIN)\n\
\n\
/**\n\
 *\n\
 */\n\
class $(CLASSNAME) {\n\
public:\n\
    /**\n\
     * Default constructor.\n\
     */\n\
    $(CLASSNAME)();\n\
    /**\n\
     * Destructor.\n\
     */\n\
    virtual ~$(CLASSNAME)();\n\
\n\
private:\n\
\n\
};\n\
\n\
$(NAMESPACE_END)\n\
#endif // $(INC_GUARDPREFIX)_$(CLASSNAME)_HPP__\n" `date +%Y` > include/$(INC_PATH)/$(CLASSNAME).hpp
	@test -f src/$(CLASSNAME).cpp || printf "/*\n\
 * @file $(CLASSNAME).cpp\n\
 *\n\
 * Copyright %d $(COMPANY). All rights reserved.\n\
 * Use is subject to license terms.\n\
 *\n\
 * \$$Id$$\n\
 * \$$Date$$\n\
 */\n\
#include \"$(INC_PATH)/$(CLASSNAME).hpp\"\n\
\n\
$(NAMESPACE_BEGIN)\n\
// --------------------------------------------------------------------\n\
// ..........................................................\n\
$(CLASSNAME)::$(CLASSNAME)() {\n\
}\n\
// ..........................................................\n\
$(CLASSNAME)::~$(CLASSNAME)() {\n\
}\n\
\n\
$(NAMESPACE_END)\n" `date +%Y` > src/$(CLASSNAME).cpp
endif

$(CLASSNAME):
	@:

endif

# create uml diagram of module from sources.
ifneq ($(MODTYPE),python)
uml: 	
	cp $(ABSROOT)/core/doxyuml.xsl $(PRJROOT)/build/doxygen/xml ; \
	cd $(PRJROOT)/build/doxygen/xml ; \
	xsltproc doxyuml.xsl index.xml > $(MODNAME).uml.xml ; \
	xsltproc $(ABSROOT)/core/uml2dot.xsl $(MODNAME).uml.xml | sed "s/\!g//g" > $(MODNAME).uml.dot ; \
	dot -T png -o $(MODNAME).dot.png $(MODNAME).uml.dot 

endif

##  - obuild: open build directory in browser
.PHONY: obuild
obuild:
ifeq ($(ISWINDOWS),true)
	@explorer `cygpath -d "$(TRDIR)"` &
else
	@xdg-open $(TRDIR) &
endif

##  - olibdoc L=<libname>: open library document directory in browser
olibdoc:
ifeq ($(ISWINDOWS),true)
	@explorer `cygpath -d "$(EXTLIBDIR)/$(filter $(L)-%,$(USELIB))/share/doc/$(L)"` &
else
	@xdg-open "$(EXTLIBDIR)/$(filter $(L)-%,$(USELIB))/share/doc/$(L)" &
endif

##  - showvar [V="<var name> [<var name>]*]": print make variables
ifeq ($(findstring showvar,$(MAKECMDGOALS)),showvar)
V?=$(.VARIABLES)
endif
showvar:
	$(foreach v,$(filter-out .VARIABLES,$(V)), $(shell echo ' $(v)=$($(v))' >> .showvars.tmp))
	@cat .showvars.tmp ; rm .showvars.tmp
