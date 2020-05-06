## 
## --------------------------------------------------------------------
## Documentation services
## 

MODNAME?=_doc
DOCDIR:=$(TRDIR)/share/doc/$(APPNAME)
PDFDIR:=$(DOCDIR)/pdf
DBDIR:=$(DOCDIR)/docbook
TEXDIR:=$(DOCDIR)/tex
DOXDIR:=$(DOCDIR)/doxygen
HTMLDIR:=$(DOCDIR)/html
JAVACMD:=java -Djava.awt.headless=true
DOXYGENCMD:=$(shell which doxygen 2>/dev/null)
DOCROOT:=$(ABSROOT)/doc
HTML_STYLE_BUNDLE+=$(patsubst %,$(ABSROOT)/doc/html/%.tar.gz,style impress.js highlight.js)

# files to be processed by doxygen.
DOXSRCFILES:=$(shell find $(PRJROOT) -name *.h -o -name *.c -o -name *.hpp -o -name *.cpp -o -name *.py -o -name *.java | fgrep -v "/build/" | fgrep -v "/dist/" | fgrep -v "$(ABSROOT)")

HEMLVERSION?=1.0.2
HEMLARGS:=-param app $(APPNAME) -param version $(VERSION) -param date "`date --rfc-3339 s`" -param user $$USER -param host $(shell hostname)

PUMLVERSION?=1.2017.12
PUMLJAR?=$(NDNA_EXTLIBDIR)/plantuml.$(PUMLVERSION).jar
HEMLJAR?=$(NDNA_EXTLIBDIR)/heml-$(HEMLVERSION).jar
HEMLCMD?=$(JAVACMD) -jar $(call absGetPath,$(HEMLJAR))
PUMLCMD?=$(JAVACMD) -jar $(call absGetPath,$(PUMLJAR))

ifeq ($(filter release,$(MAKECMDGOALS)),)
DISABLE_SRC+=$(RELEASE_NOTE)
else
src/$(RELEASE_NOTE): scm-release

release: all
endif

HEMLS?=$(filter %.heml,$(filter-out $(patsubst %,src/%,$(DISABLE_SRC)),$(SRCFILES)))
PDFLATEX:=$(shell which pdflatex 2>/dev/null)
METAFONT:=$(shell which mf 2>/dev/null)
HASLATEX:=false
ifneq ($(PDFLATEX),)
ifneq ($(METAFONT),)
HASLATEX:=true
endif
endif

ifneq ($(DOC_FAIL_ON_ERROR),true)
DOC_FAIL_ON_ERROR:=false
endif

ifeq ($(HASLATEX),true)
TEXFOT:=$(shell which texfot 2>/dev/null)
ifneq ($(TEXFOT),)
TEXFOT:=$(TEXFOT) --tee=/dev/null
endif
PDFS:=$(patsubst src/%.heml,$(PDFDIR)/%.pdf,$(HEMLS))
endif
DOCBOOKS:=$(patsubst src/%.heml,$(DBDIR)/%.xml,$(HEMLS))
HTMLS:=$(patsubst src/%.heml,$(HTMLDIR)/%.html,$(HEMLS)) $(HTMLDIR)/style.css
IMGS:=$(patsubst src/%,$(HTMLDIR)/%,$(filter %.jpg %.png,$(SRCFILES))) $(patsubst src/%.dia,$(HTMLDIR)/%.png,$(filter %.dia,$(SRCFILES)))
IMGSUML:=$(patsubst src/%.heml,$(OBJDIR)/%.pumlgenerated,$(HEMLS))
## XSL Stylesheets definition:
##   - HEMLTOTEX_STYLE: tex (pdf)
##   - HEMLTOXHTML_STYLE: html
##   - HEMLTOXML_STYLE: docbook
HEMLTOTEX_STYLE?=$(DOCROOT)/tex/style.tex.xsl $(HEMLTOTEX_FLAGS)
HEMLTOXHTML_STYLE?=$(DOCROOT)/html/style.xhtml.xsl $(HEMLTOXHTML_FLAGS)
HEMLTOXML_STYLE?=$(DOCROOT)/docbook/style.docbook.xsl $(HEMLTOXML_FLAGS)

## Documentation targets:
## 
##  - all: for documentation module, the default target builds html, pdf
##      from heml files, and doxygen reference.
all-impl:: $(HTMLS) $(PDFS) $(IMGS) $(IMGSUML)

.PRECIOUS: $(HEMLJAR) $(PUMLJAR) $(patsubst $(NDNA_EXTLIBDIR)/%,$(ABS_CACHE)/noarch/%,$(HEMLJAR) $(PUMLJAR)) $(IMGS) $(TEXDIR)/%.tex $(OBJDIR)/%.pumlgenerated

ifneq ($(DOXYGENCMD),)
all-impl:: $(DOXDIR)

$(DOXDIR): $(DOXSRCFILES)
	@$(ABS_PRINT_info) "Generating API reference documentation..."
	@m4 -D__project_name__=$(APPNAME) -D__project_number__=$(VERSION) -D__output_directory__=$(DOXDIR) -D__abs_root__=$(ABSROOT) -D__prj_module_list__="$(patsubst %/module.cfg,%,$(wildcard $(PRJROOT)/*/module.cfg))" $(ABSROOT)/doc/doxygen/Doxyfile > $(TRDIR)/.Doxyfile
	@$(DOXYGENCMD) $(TRDIR)/.Doxyfile
	@rm -rf $(TRDIR)/.Doxyfile
else
$(DOXDIR):
	@$(ABS_PRINT_warning) "Doxygen not available, doxygen generation skipped."
endif

$(HTMLDIR)/%.css: src/%.css
	@mkdir -p $(@D)
	cp $^ $@

$(HTMLDIR)/style.css: $(HTML_STYLE_BUNDLE)
	@$(ABS_PRINT_info) "Extracting html style bundles:"
	@mkdir -p $(@D)
	@for tarball in $^ ; do \
	$(ABS_PRINT_info) "  - $$tarball" ; \
	tar -C $(@D) -xzf $$tarball && touch $@ ; \
	done

$(HTMLDIR)/%.jpg: src/%.jpg
	@mkdir -p $(@D)
	cp $^ $@

$(HTMLDIR)/%.png: src/%.png
	@mkdir -p $(@D)
	cp $^ $@

DIACMD:=$(shell which dia 2>/dev/null)
ifeq ($(DIACMD),)
$(HTMLDIR)/%.png: src/%.dia
	@$(ABS_PRINT_warning) "dia is not available for $^ rendering."
	@mkdir -p $(@D)
	@cp $(ABSROOT)/doc/diamissing.png $@
else
$(HTMLDIR)/%.png: src/%.dia
	@$(ABS_PRINT_info) "Rendering dia file $^..."
	@mkdir -p $(@D)
	@MROOT=`pwd` ; cd $(@D) ; dia -t png $$MROOT/$^
endif

$(OBJDIR)/%.pumlgenerated: src/%.heml $(PUMLJAR)
	@mkdir -p $(@D)
	@mkdir -p $(HTMLDIR)/$(*D)
	@$(ABS_PRINT_info) "Generating uml from $<"
	@$(PUMLCMD) -in $(call absGetPath,$<) -o $(call absGetPath,$(HTMLDIR)/$(*D))
	@touch $@

# HEML transformation
# $1 xsl file
define absHemlTransformation
	@$(ABS_PRINT_info) "heml to $(suffix $@) of $< using style $(1)"
	@mkdir -p $(@D)
	@$(HEMLCMD) -in $(call absGetPath,$<) -xsl $(call absGetPath,$(1)) -param srcdir "$(call absGetPath,$(<D))" -param srcfilename "$(call absGetPath,$(<F))" $(HEMLARGS) -param revision ""`$(call abs_scm_file_revision,$<)` -out $(call absGetPath,$@)
endef

$(HTMLDIR)/%.html: src/%.heml $(HEMLJAR)
	$(call absHemlTransformation,$(HEMLTOXHTML_STYLE))

$(DBDIR)/%.xml: src/%.heml $(HEMLJAR)
	$(call absHemlTransformation,$(HEMLTOXML_STYLE))

$(TEXDIR)/%.tex: src/%.heml $(HEMLJAR)
	$(call absHemlTransformation,$(HEMLTOTEX_STYLE))

TEXINPUTS:=$(TEXINPUTS):$(ABSROOT)/doc/tex//:$(OBJDIR):$(TEXDIR):$(HTMLDIR):$(CURDIR)/src
TEXENV=TEXINPUTS=$(TEXINPUTS):

$(PDFDIR)/%.pdf: $(TEXDIR)/%.tex $(IMGS) $(OBJDIR)/%.pumlgenerated
	@$(ABS_PRINT_info) "Processing TEX $<"
	@mkdir -p $(@D)
	@mkdir -p $(OBJDIR)
	@# remove previous generated elements to avoid references problems.
	@rm -f $(OBJDIR)/$(*F).aux $(OBJDIR)/$(*F).lo* $(OBJDIR)/$(*F).out $(OBJDIR)/$(*F).toc
ifneq ($(USER),jenkins)
	@cd $(OBJDIR) && $(TEXENV) $(TEXFOT) pdflatex --interaction nonstopmode $< > $(OBJDIR)/tex.$(@F).log && pass=2 && \
		while [ "`cat $(OBJDIR)/tex.$(@F).log | grep \"Rerun to get cross-references right\"`" != "" ]; do \
			$(ABS_PRINT_info) "Pass number $$pass for $(@F)" && \
			pass=`expr $$pass + 1` && \
			$(TEXENV) pdflatex --interaction nonstopmode $< > $(OBJDIR)/tex.$(@F).log; \
		done || (cat $(OBJDIR)/tex.$(@F).log && ! $(DOC_FAIL_ON_ERROR))
	@mv $(OBJDIR)/$(@F) $(@D)
else
	@cd $(OBJDIR) && $(TEXENV) pdflatex --interaction nonstopmode $< > $(OBJDIR)/tex.$(@F).log && pass=2 && \
		while [ "`cat $(OBJDIR)/tex.$(@F).log | grep \"Rerun to get cross-references right\"`" != "" ]; do \
			$(ABS_PRINT_info) "Pass number $$pass for $(@F)" && \
			pass=`expr $$pass + 1` && \
			$(TEXENV) pdflatex --interaction nonstopmode $< > $(OBJDIR)/tex.$(@F).log; \
		done || ($(ABS_PRINT_error) "pdf generation error see $(OBJDIR)/tex.$(@F).log for more information." && ! $(DOC_FAIL_ON_ERROR))
	@mv $(OBJDIR)/$(@F) $(@D) || $(ABS_PRINT_error) "$@ generation failed."
endif

##  - html: generates html files and companion images from heml files.
html: $(HTMLS) $(IMGS) $(IMGSUML)

##  - pdf: generates pdf files and companion images from heml files. pdf 
##    generation is available only from host having a latex package including
##    the pdflatex command.
ifneq ($(HASLATEX),true)
pdf:
	@$(ABS_PRINT_warning) "pdflatex or metafont are not available, can't generate pdf files."
else
pdf: $(PDFS)
endif

docbook: $(DOCBOOKS)


clean::
	rm -rf $(DOCDIR)

##  - odoc L=<libname>: open application document directory in browser
odoc:
ifeq ($(ISWINDOWS),true)
	@explorer `cygpath -d "$(TRDIR)/share/doc/$(APPNAME)"` &
else
	@xdg-open "$(TRDIR)/share/doc/$(APPNAME)" &
endif

