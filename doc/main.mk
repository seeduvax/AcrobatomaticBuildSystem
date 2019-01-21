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
HTML_STYLE_BUNDLE:= $(PRJROOT)/.abs/doc/html/style.tar.gz

# files to be processed by doxygen.
DOXSRCFILES:=$(shell find $(PRJROOT) -name *.h -o -name *.c -o -name *.hpp -o -name *.cpp -o -name *.py -o -name *.java | fgrep -v "/build/" | fgrep -v "/dist/" | fgrep -v "/.abs/")

HEMLVERSION:=0.1.0-1550
HEMLARGS:=-param app $(APPNAME) -param version $(VERSION) -param date "`date --rfc-3339 s`" -param user $$USER -param host $(shell hostname)

PUMLVERSION:=1.2017.12
PUMLJAR:=$(NDNA_EXTLIBDIR)/plantuml.$(PUMLVERSION).jar
HEMLJAR:=$(NDNA_EXTLIBDIR)/heml-$(HEMLVERSION).jar
HEMLCMD:=$(JAVACMD) -jar $(call absGetPath,$(HEMLJAR))
PUMLCMD:=$(JAVACMD) -jar $(call absGetPath,$(PUMLJAR))

HEMLS:=$(filter-out %_release.heml,$(shell find src -name "*.heml"))
PDFLATEX:=$(shell which pdflatex 2>/dev/null)
METAFONT:=$(shell which mf 2>/dev/null)
HASLATEX:=false
ifneq ($(PDFLATEX),)
ifneq ($(METAFONT),)
HASLATEX:=true
endif
endif

ifeq ($(HASLATEX),true)
TEXFOT:=$(shell which texfot 2>/dev/null)
ifneq ($(TEXFOT),)
TEXFOT:=$(TEXFOT) --tee=/dev/null
endif
PDFS:=$(patsubst src/%.heml,$(PDFDIR)/%.pdf,$(HEMLS))
endif
DOCBOOKS:=$(patsubst src/%.heml,$(DBDIR)/%.xml,$(HEMLS))
HTMLS:=$(patsubst src/%.heml,$(HTMLDIR)/%.html,$(HEMLS)) $(HTMLDIR)/style.css $(HTMLDIR)/highlight/highlight.js
IMGS:=$(patsubst src/%,$(HTMLDIR)/%,$(shell find src -name "*.jpg")) $(patsubst src/%,$(HTMLDIR)/%,$(shell find src -name "*.png")) $(patsubst src/%.dia,$(HTMLDIR)/%.png,$(shell find src -name "*.dia"))
## XSL Stylesheets definition:
##   - HEMLTOTEX_STYLE: tex (pdf)
##   - HEMLTOXHTML_STYLE: html
##   - HEMLTOXML_STYLE: docbook
HEMLTOTEX_STYLE?=$(DOCROOT)/tex/style.tex.xsl
HEMLTOXHTML_STYLE:=$(DOCROOT)/html/style.xhtml.xsl
HEMLTOXML_STYLE:=$(DOCROOT)/docbook/style.docbook.xsl

## Documentation targets:
## 
##  - all: for documentation module, the default target builds html, pdf
##      from heml files, and doxygen reference.
all-impl:: $(HTMLS) $(PDFS)

.PRECIOUS: $(HEMLJAR) $(PUMLJAR) $(patsubst $(NDNA_EXTLIBDIR)/%,$(ABS_CACHE)/noarch/%,$(HEMLJAR) $(PUMLJAR)) $(IMGS) $(TEXDIR)/%.tex

ifneq ($(DOXYGENCMD),)
all-impl:: $(DOXDIR)

$(DOXDIR): $(DOXSRCFILES)
	@$(ABS_PRINT_info) "Generating API reference documentation..."
	@m4 -D__project_name__=$(APPNAME) -D__project_number__=$(VERSION) -D__output_directory__=$(DOXDIR) -D__prj_root__=$(PRJROOT) -D__prj_module_list__="$(patsubst %/module.cfg,%,$(wildcard $(PRJROOT)/*/module.cfg))" $(PRJROOT)/.abs/doc/doxygen/Doxyfile > $(TRDIR)/.Doxyfile
	@$(DOXYGENCMD) $(TRDIR)/.Doxyfile
	@rm -rf $(TRDIR)/.Doxyfile
else
$(DOXDIR):
	@$(ABS_PRINT_warning) "Doxygen not available, doxygen generation skipped."
endif

$(HTMLDIR)/%.css: src/%.css
	@mkdir -p $(@D)
	cp $^ $@

$(HTMLDIR)/%.css: $(HTML_STYLE_BUNDLE)
	@$(ABS_PRINT_info) "Extracting style bundle..."
	@mkdir -p $(@D)
	@tar -C $(@D) -xzf $^ && touch $@

$(HTMLDIR)/highlight/highlight.js: $(PRJROOT)/.abs/doc/html/highlight.js.tar.gz
	@$(ABS_PRINT_info) "Extracting syntax highlight.js bundle..."
	@mkdir -p $(@D)
	@tar -C `dirname $(@D)` -xzf $^ && touch $@

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
	@cp $(PRJROOT)/.abs/doc/diamissing.png $@
else
$(HTMLDIR)/%.png: src/%.dia
	@$(ABS_PRINT_info) "Rendering dia file $^..."
	@mkdir -p $(@D)
	@MROOT=`pwd` ; cd $(@D) ; dia -t png $$MROOT/$^
endif

# HEML transformation
# $1 xsl file
define absHemlTransformation
	@$(ABS_PRINT_info) "heml to $(suffix $@) of $< using style $(1)"
	@mkdir -p $(@D)
	@$(PUMLCMD) -in $(call absGetPath,$<) -o $(call absGetPath,$(@D))
	@$(HEMLCMD) -in $(call absGetPath,$<) -xsl $(call absGetPath,$(1)) -param srcdir "$(call absGetPath,$(<D))" $(HEMLARGS) -out $(call absGetPath,$@)
endef

$(HTMLDIR)/%.html: src/%.heml $(HEMLJAR) $(PUMLJAR) $(IMGS)
	$(call absHemlTransformation,$(HEMLTOXHTML_STYLE))

$(DBDIR)/%.xml: src/%.heml $(HEMLJAR) $(PUMLJAR)
	$(call absHemlTransformation,$(HEMLTOXML_STYLE))

$(TEXDIR)/%.tex: src/%.heml $(HEMLJAR) $(PUMLJAR)
	$(call absHemlTransformation,$(HEMLTOTEX_STYLE))

TEXINPUTS+=$(PRJROOT)/.abs/doc/tex//:$(OBJDIR):$(TEXDIR):$(HTMLDIR):$(CURDIR)/src
TEXENV=TEXINPUTS=$(TEXINPUTS):

$(PDFDIR)/%.pdf: $(TEXDIR)/%.tex $(IMGS)
	@$(ABS_PRINT_info) "Processing TEX $<"
	@mkdir -p $(@D)
	@mkdir -p $(OBJDIR)
ifneq ($(USER),jenkins)
	@cd $(OBJDIR) && $(TEXENV) $(TEXFOT) pdflatex --interaction nonstopmode $< > $(OBJDIR)/tex.$(@F).log && $(TEXENV) pdflatex --interaction nonstopmode $< > $(OBJDIR)/tex.$(@F).log || cat $(OBJDIR)/tex.$(@F).log
	@mv $(OBJDIR)/$(@F) $(@D)
else
	@cd $(OBJDIR) && $(TEXENV) pdflatex --interaction nonstopmode $< > $(OBJDIR)/tex.$(@F).log && $(TEXENV) pdflatex --interaction nonstopmode $< > $(OBJDIR)/tex.$(@F).log || $(ABS_PRINT_error) "pdf generation error see $(OBJDIR)/tex.$(@F).log for more information."
	@mv $(patsubst $(PDFDIR)/%.pdf,$(OBJDIR)/%.pdf,$@) $(@D) || $(ABS_PRINT_error) "$@ generation failed."
endif

##  - html: generates html files and companion images from heml files.
html: $(HTMLS)

##  - pdf: generates pdf files and companion images from heml files. pdf 
##    generation is available only from host having a latex package including
##    the pdflatex command.
ifneq ($(HASLATEX),true)
pdf:
	@$(ABS_PRINT_warning) "pdflatex or metafont are not available, can't generate pdf file."
else
pdf: $(PDFS)
endif

docbook: $(DOCBOOKS)

$(PRJROOT)/build/release.spec:
	@APPNAME=$(APPNAME) PRJROOT=$(PRJROOT) VPARENT=$(VPARENT) VERSION=$(VERSION) VISSUE=$(VISSUE) $(PRJROOT)/.abs/doc/release-info.sh
	@touch $@

##  - release: generates release note (pdf only). Source file for relase note
##      naming scheme is src/%_release.heml
ifeq ($(VPARENT),)
release:
	@$(ABS_PRINT_error) "Can't make release, VPARENT is undefined" ; exit 1
else ifeq ($(VISSUE),)
release:
	@$(ABS_PRINT_error) "Can't make release, VISSUE is undefined" ; exit 1
else
release: $(PRJROOT)/build/release.spec $(patsubst src/%.heml,$(PDFDIR)/%.pdf,$(shell find src -name "*_release.heml"))
endif

clean::
	rm -rf $(DOCDIR)
	rm -rf $(PRJROOT)/build/release.spec

