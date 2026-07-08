## 
## --------------------------------------------------------------------
## Documentation services
## 
## Variables
## 	  DOC_PDF_GENERATOR: indicates the generator of pdf to use.
##		- latex: use texlive to generate pdf
##		- chrome: use chrome (chromium) binary to generate pdf
##		- nodejs: use nodejs with playwright to generate pdf (need chromium)
MODNAME?=_doc
DOC_PDF_GENERATOR?=latex
DOCDIR:=$(TRDIR)/share/doc/$(APPNAME)
PDFDIR:=$(DOCDIR)/pdf
DBDIR:=$(DOCDIR)/docbook
TEXDIR:=$(DOCDIR)/tex
DOXDIR:=$(DOCDIR)/doxygen
HTMLDIR:=$(DOCDIR)/html
JAVACMD:=java -Djava.awt.headless=true
DOXYGENCMD:=$(shell which doxygen 2>/dev/null)
DOCROOT:=$(ABSROOT)/doc
# when changing version of HtmlToBook, change it in style.xhtml.pdf.xsl too
HTML_STYLE_BUNDLE+=$(patsubst %,$(ABSROOT)/doc/html/%.tar.gz,impress.js highlight.js mathjax.js HtmlToBook-1.0.0.noarch)
HTML_STYLE_EXTRACTED=$(OBJDIR)/.html_style.extracted
# user for continous integration.
CI_USER?=jenkins

# files to be processed by doxygen.
DOXSRCFILES:=$(shell find $(PRJROOT) -name *.h -o -name *.c -o -name *.hpp -o -name *.cpp -o -name *.py -o -name *.java | fgrep -v "/build/" | fgrep -v "/dist/" | fgrep -v "$(ABSROOT)")

HEMLVERSION?=1.0.15
HEMLARGS:=-param app $(APPNAME) -param version $(VERSION) -param date "`date --rfc-3339 s`" -param user "$(USER)" -param host $(shell hostname)

PUMLVERSION?=1.2021.6
LUAJVERSION?=3.0.1
PUMLJAR?=$(ABS_CACHE)/noarch/plantuml-$(PUMLVERSION).jar
PUMLJARTG?=$(ABS_CACHE)/noarch/plantuml/$(PUMLVERSION)/pck.jar
LUAJJAR?=$(ABS_CACHE)/noarch/luaj-jse-$(LUAJVERSION).jar
LUAJJARTG?=$(ABS_CACHE)/noarch/luaj-jse/$(LUAJVERSION)/pck.jar
HEMLJAR?=$(ABS_CACHE)/noarch/heml-$(HEMLVERSION).jar
HEMLJARTG?=$(ABS_CACHE)/noarch/heml/$(HEMLVERSION)/pck.jar
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
endif
PDFS:=$(patsubst src/%.heml,$(PDFDIR)/%.pdf,$(HEMLS))
DOCBOOKS:=$(patsubst src/%.heml,$(DBDIR)/%.xml,$(HEMLS))
HTMLS:=$(patsubst src/%.heml,$(HTMLDIR)/%.html,$(HEMLS))
HTMLS+=$(patsubst src/%.heml,$(HTMLDIR)/%.pdf.html,$(HEMLS)) 
CSS:=$(patsubst src/%,$(HTMLDIR)/%,$(filter %.css,$(SRCFILES)))
CSS+=$(patsubst $(DOCROOT)/html/%,$(HTMLDIR)/%,$(wildcard $(DOCROOT)/html/css/*.css))
CSS+=$(patsubst $(DOCROOT)/html/%,$(HTMLDIR)/%,$(wildcard $(DOCROOT)/html/images/*.png) $(wildcard $(DOCROOT)/html/images/*.jpg))
CSS+=$(HTML_STYLE_EXTRACTED)

ABSDOCDIR:=$(dir $(lastword $(MAKEFILE_LIST)))

ifneq ($(MAKECMDGOALS),clean)
-include $(patsubst src/%.heml,$(OBJDIR)/%.html.d,$(HEMLS))
ifeq ($(HASLATEX),true)
-include $(patsubst src/%.heml,$(OBJDIR)/%.tex.d,$(HEMLS))
endif

TESTINDEXES:=
TESTSRCFILES:=$(wildcard $(PRJROOT)/*/test/Test*.cpp)
ifneq ($(TESTSRCFILES),)
$(OBJDIR)/testdefindex.heml: $(TESTSRCFILES)
	@$(ABS_PRINT_info) "Generating automated test cases index..."
	@echo "{testdef" > $@
	@for testmoduledir in $(PRJROOT)/* ; do \
	  echo $$testmoduledir ; \
	  test -d "$$testmoduledir/test" && echo " {testmodule %name="`basename "$$testmoduledir"` >> $@ || : ; \
	  for testcasefile in "$$testmoduledir/test/Test"*.cpp ; do \
		echo $$testcasefile ; \
		testDocfile=$(OBJDIR)/`basename "$$testmoduledir"`_`basename $$testcasefile` ;\
		testDocfile=`echo $$testDocfile | sed s/.cpp/.heml/ `;\
		test -r "$$testcasefile" && grep -v "#\s*include" "$$testcasefile" | cpp -E | fgrep "ABS_TEST_" | sed -E 's/\{ *$$//g' | cpp -D__TESTFILE__="$$testcasefile" -include $(ABSROOT)/core/include/abs/testdef2heml.h | sed -e "/^# /d;s:$(PRJROOT)::g;s/{/\n{/g" > $$testDocfile || : ; \
		test -r "$$testcasefile" && echo "   {?include %src="$$testDocfile" }" >> $@ || : ; \
	  done ; \
	  test -d "$$testmoduledir/test" && echo " }" >> $@ || : ; \
	done
	@echo "}" >> $@
else
$(OBJDIR)/testdefindex.heml:
	@touch $@

endif
TESTINDEXES+=$(OBJDIR)/testdefindex.heml

TESTEXECFILES:=$(wildcard $(TRDIR)/test/*.stdout)
ifneq ($(TESTEXECFILES),)
$(OBJDIR)/testexecindex.heml: $(TESTEXECFILES)
	@$(ABS_PRINT_info) "Generating automated test cases execution index..."
	@echo "{testexec" > $@
	@for testfile in $(TESTEXECFILES) ; do \
	    echo "{testmodule %name="`basename $$testfile | sed -e 's/.stdout$$//g;s/$(APPNAME)_//g'` >> $@ ; \
	    echo "{dummy" >> $@ ; \
	    fgrep "ABS_TEST_" "$$testfile" | sed -E 's/\{ *$$//g' | cpp -include $(ABSROOT)/core/include/abs/testdef2heml.h | sed -e "/^# /d;s/{testcase/}{testcase/g" >> $@ ; \
		echo "}" >> $@ ; \
		echo "}" >> $@ ; \
	done
	@echo "}" >> $@
else
$(OBJDIR)/testexecindex.heml:
	@touch $@

endif
TESTINDEXES+=$(OBJDIR)/testexecindex.heml

$(OBJDIR)/pumldeps.mk: $(SRCFILES)
	@mkdir -p $(@D)
	@$(if $(SRCFILES),$(ABSDOCDIR)/pumldeps.sh $(SRCFILES) > $@)

include $(OBJDIR)/pumldeps.mk

ifeq ($(wildcard $(OBJDIR)/*.html.d)$(wildcard $(OBJDIR)/*.tex.d),)
# when no generation has been done yet, add all images as deps.
IMGS:=$(patsubst src/%,$(HTMLDIR)/%,$(filter %.jpg %.png,$(SRCFILES))) $(patsubst src/%.dia,$(HTMLDIR)/%.png,$(filter %.dia,$(SRCFILES))) $(PUMLGENIMGS)
endif
endif

## XSL Stylesheets definition:
##   - HEMLTOTEX_STYLE: tex (pdf)
##   - HEMLTOXHTML_STYLE: html
##	 - HEMLTOHTMLPDF_STYLE: html to pdf
##   - HEMLTOXML_STYLE: docbook
HEMLTOTEX_STYLE?=$(DOCROOT)/tex/style.tex.xsl $(HEMLTOTEX_FLAGS)
HEMLTOXHTML_STYLE?=$(DOCROOT)/html/style.xhtml.xsl $(HEMLTOXHTML_FLAGS)
HEMLTOHTMLPDF_STYLE?=$(DOCROOT)/html/style.xhtml_pdf.xsl $(HEMLTOXHTML_FLAGS)
HEMLTOXML_STYLE?=$(DOCROOT)/docbook/style.docbook.xsl $(HEMLTOXML_FLAGS)

## Documentation targets:
## 
##  - all: for documentation module, the default target builds html, pdf
##      from heml files, and doxygen reference.
TARGETFILES+=$(HTMLS) $(PDFS)

$(HTMLS) $(PDFS): $(IMGS)

$(HTMLS): $(CSS)

.PRECIOUS: $(HEMLJAR) $(LUAJJARTG) $(PUMLJARTG) $(patsubst $(NDNA_EXTLIBDIR)/%,$(ABS_CACHE)/noarch/%,$(HEMLJARTG) $(PUMLJARTG)) $(IMGS) $(TEXDIR)/%.tex $(OBJDIR)/%.pumlgenerated

ifneq ($(DOXYGENCMD),)
TARGETFILES+=$(DOXDIR)

$(DOXDIR): $(DOXSRCFILES)
	@$(ABS_PRINT_info) "Generating API reference documentation..."
	@mkdir -p $(DOXDIR)
	@m4 -D__project_name__=$(APPNAME) -D__project_number__=$(VERSION) -D__output_directory__=$(DOXDIR) -D__abs_root__=$(ABSROOT) -D__prj_module_list__="$(patsubst %/module.cfg,%,$(wildcard $(PRJROOT)/*/module.cfg))" $(ABSROOT)/doc/doxygen/Doxyfile > $(TRDIR)/.Doxyfile
	@$(DOXYGENCMD) $(TRDIR)/.Doxyfile
	@rm -rf $(TRDIR)/.Doxyfile
else
$(DOXDIR):
	@$(ABS_PRINT_warning) "Doxygen not available, doxygen generation skipped."
endif

$(HTMLDIR)/%.css: src/%.css
	@$(ABS_PRINT_info) "Publishing $<..."
	@mkdir -p $(@D)
	@cp $^ $@

$(HTMLDIR)/%.css: $(DOCROOT)/html/%.css
	@mkdir -p $(@D)
	@cp $^ $@

$(HTML_STYLE_EXTRACTED): $(HTML_STYLE_BUNDLE)
	@$(ABS_PRINT_info) "Extracting html style bundles:"
	@mkdir -p $(@D)
	@mkdir -p $(HTMLDIR)
	@for tarball in $(HTML_STYLE_BUNDLE) ; do \
	$(ABS_PRINT_info) "  - $$tarball" ; \
	tar -C $(HTMLDIR) -xzf $$tarball ; \
	done
	@touch $(HTML_STYLE_EXTRACTED)

$(HTMLDIR)/%.jpg: src/%.jpg
	@mkdir -p $(@D)
	@cp $^ $@

$(HTMLDIR)/%.png: src/%.png
	@mkdir -p $(@D)
	@cp $^ $@

$(HTMLDIR)/%.jpg: $(DOCROOT)/html/%.jpg
	@mkdir -p $(@D)
	@cp $^ $@

$(HTMLDIR)/%.png: $(DOCROOT)/html/%.png
	@mkdir -p $(@D)
	@cp $^ $@

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

$(OBJDIR)/%.pumlgenerated: src/% $(PUMLJARTG)
	@mkdir -p $(@D)
	@mkdir -p $(HTMLDIR)/$(*D)
	@$(ABS_PRINT_info) "Generating uml from $<"
	@$(PUMLCMD) -in $(call absGetPath,$<) -o $(call absGetPath,$(HTMLDIR)/$(*D))
	@date > $@
	@echo "$<" >> $@

COMMENTS?=true
# HEML transformation
# $1 xsl file
define absHemlTransformation
	@$(ABS_PRINT_info) "heml to $(suffix $@) of $< using style $1: $(@F)"
	@mkdir -p $(@D)
	@mkdir -p $(patsubst src/%,$(OBJDIR)/%,$(<D))
	@$(HEMLCMD) -in $(call absGetPath,$<) -xsl $(call absGetPath,$1) -path $(OBJDIR) -param srcdir "$(call absGetPath,$(<D))" -param srcfilename "$(call absGetPath,$(<F))" $(HEMLARGS) -param revision ""`$(call abs_scm_file_revision,$<)` -param showComments ""$(COMMENTS) -out $(call absGetPath,$@) -depattr fig:src:$(patsubst %/,%,$(patsubst src%,$(HTMLDIR)/%,$(<D)))
endef

$(HTMLDIR)/%.html: src/%.heml $(HEMLJARTG) $(LUAJJARTG) $(TESTINDEXES)
	$(call absHemlTransformation,$(HEMLTOXHTML_STYLE) -dep $(patsubst $(HTMLDIR)/%,$(OBJDIR)/%.d,$@))

$(HTMLDIR)/%.pdf.html: src/%.heml $(HEMLJARTG) $(LUAJJARTG) $(TESTINDEXES)
	$(call absHemlTransformation,$(HEMLTOHTMLPDF_STYLE) -dep $(patsubst $(HTMLDIR)/%,$(OBJDIR)/%.d,$@))

$(DBDIR)/%.xml: src/%.heml $(HEMLJARTG) $(LUAJJARTG) $(TESTINDEXES)
	$(call absHemlTransformation,$(HEMLTOXML_STYLE) -dep $(patsubst $(DBDIR)/%,$(OBJDIR)/%.d,$@))

$(TEXDIR)/%.tex: src/%.heml $(HEMLJARTG) $(LUAJJARTG) $(IMGS) $(TESTINDEXES)
	$(call absHemlTransformation,$(HEMLTOTEX_STYLE) -dep $(patsubst $(TEXDIR)/%,$(OBJDIR)/%.d,$@))

TEXDEFAULTINPUTS?=:
ifneq ($(TEXINPUTS),)
TEXINPUTS:=$(TEXINPUTS):
endif
TEXINPUTS:=$(TEXINPUTS)$(ABSROOT)/doc/tex//:$(OBJDIR):$(TEXDIR):$(HTMLDIR):$(CURDIR)/src$(TEXDEFAULTINPUTS)
TEXENV=TEXINPUTS=$(TEXINPUTS)

ifeq ($(DOC_PDF_GENERATOR),latex)
ifeq ($(HASLATEX),true)
$(PDFDIR)/%.pdf: $(TEXDIR)/%.tex
	@$(ABS_PRINT_info) "Processing TEX $<"
	@mkdir -p $(@D)
	@mkdir -p $(OBJDIR)
	@# remove previous generated elements to avoid references problems.
	@rm -f $(OBJDIR)/$(*F).aux $(OBJDIR)/$(*F).lo* $(OBJDIR)/$(*F).out $(OBJDIR)/$(*F).toc
ifneq ($(USER),$(CI_USER))
	@cd $(OBJDIR) && $(TEXENV) $(TEXFOT) $(PDFLATEX) --interaction nonstopmode $< > $(OBJDIR)/tex.$(@F).log && pass=2 && \
		while [ "`cat $(OBJDIR)/tex.$(@F).log | grep \"Rerun to get cross-references right\"`" != "" ]; do \
			$(ABS_PRINT_info) "Pass number $$pass for $(@F)" && \
			pass=`expr $$pass + 1` && \
			$(TEXENV) $(PDFLATEX) --interaction nonstopmode $< > $(OBJDIR)/tex.$(@F).log; \
		done || (cat $(OBJDIR)/tex.$(@F).log && ! $(DOC_FAIL_ON_ERROR))
	@mv $(OBJDIR)/$(@F) $(@D)
else
	@cd $(OBJDIR) && $(TEXENV) $(PDFLATEX) --interaction nonstopmode $< > $(OBJDIR)/tex.$(@F).log && pass=2 && \
		while [ "`cat $(OBJDIR)/tex.$(@F).log | grep \"Rerun to get cross-references right\"`" != "" ]; do \
			$(ABS_PRINT_info) "Pass number $$pass for $(@F)" && \
			pass=`expr $$pass + 1` && \
			$(TEXENV) $(PDFLATEX) --interaction nonstopmode $< > $(OBJDIR)/tex.$(@F).log; \
		done || ($(ABS_PRINT_error) "pdf generation error see $(OBJDIR)/tex.$(@F).log for more information." && ! $(DOC_FAIL_ON_ERROR))
	@mv $(OBJDIR)/$(@F) $(@D) || $(ABS_PRINT_error) "$@ generation failed."
endif
endif
endif

ifeq ($(DOC_PDF_GENERATOR),nodejs)

NODE?=$(shell which node 2>/dev/null)

$(OBJDIR)/.playwright.extracted:
	@mkdir -p $(@D)
	@tar -xf $(DOCROOT)/html/playwright-core.tar.gz -C $(@D)
	@touch $@

.PRECIOUS: $(OBJDIR)/%.print.js
$(OBJDIR)/%.print.js: $(HTMLDIR)/%.pdf.html $(CSS)
	@mkdir -p $(@D)
	@CHROME_PATH="$(shell which chromium 2>/dev/null)" && sed -e "s~{PATH_HTML}~file://$<~g" \
		-e "s~{PATH_BROWSER}~$$CHROME_PATH~g" \
		-e "s~{OUTPUT}~$(OBJDIR)/$(*F).pdf~g" \
		-e "s~{EXPORT}~$(OBJDIR)/$(*F).export.html~g" $(ABSROOT)/doc/html/print.js > $@

$(PDFDIR)/%.pdf: $(OBJDIR)/%.print.js $(OBJDIR)/.playwright.extracted
	@mkdir -p $(@D)
	@test -n $(NODE) || $(ABS_PRINT_error) "No node interpreter found!"
	@cd $(OBJDIR) && $(ABS_PRINT_info) "Generating PDF..." && $(NODE) $<
	@sed -n '/<bookmarks.*>/,/<\/bookmarks>/p' $(OBJDIR)/$(*F).export.html | \
		sed -z 's/<[^>]*>//g; s/^[[:space:]]*//; s/[[:space:]]*$$//' | \
		sed 's/&nbsp;/ /g' > $(OBJDIR)/$(*F).bookmarks.ps
	@gs -dBATCH -dNOPAUSE -dQUIET \
		-sDEVICE=pdfwrite \
		-sOutputFile=$@ \
		$(OBJDIR)/$(*F).pdf $(OBJDIR)/$(*F).bookmarks.ps
	@$(ABS_PRINT_info) "File $@ created"

endif

ifeq ($(DOC_PDF_GENERATOR),chrome)

$(PDFDIR)/%.pdf: $(HTMLDIR)/%.pdf.html $(CSS)
	@mkdir -p $(@D)
	@mkdir -p $(OBJDIR)
	@chromium --headless --disable-gpu --dump-dom $< | \
		sed -n '/<bookmarks.*>/,/<\/bookmarks>/p' | \
		sed -z 's/<[^>]*>//g; s/^[[:space:]]*//; s/[[:space:]]*$$//' | \
		sed 's/&nbsp;/ /g' > $(OBJDIR)/$(*F).bookmarks.ps
	@chromium --headless --disable-gpu --no-pdf-header-footer --print-to-pdf="$@.tmp" $< 
	gs -dBATCH -dNOPAUSE -dQUIET \
		-sDEVICE=pdfwrite \
		-sOutputFile=$@ \
		$@.tmp $(OBJDIR)/$(*F).bookmarks.ps
	@rm $@.tmp
endif

##  - html: generates html files and companion images from heml files.
html: $(HTMLS)

##  - pdf: generates pdf files and companion images from heml files. pdf 
##    generation is available only from host having a latex package including
##    the pdflatex command.
ifeq ($(DOC_PDF_GENERATOR),latex)
ifneq ($(HASLATEX),true)
pdf:
	@$(ABS_PRINT_warning) "pdflatex or metafont are not available, can't generate pdf files."
else
pdf: $(PDFS)
endif
else
pdf: $(PDFS)
endif

docbook: $(DOCBOOKS)


clean::
	@$(ABS_PRINT_info) "Deleting generated doc dir <builddir>/share/doc/$(APPNAME)"
	@rm -rf $(DOCDIR)

##  - odoc L=<libname>: open application document directory in browser
odoc:
ifeq ($(ISWINDOWS),true)
	@explorer `cygpath -d "$(TRDIR)/share/doc/$(APPNAME)"` &
else
	@xdg-open "$(TRDIR)/share/doc/$(APPNAME)" &
endif


## - procreport <heml document>: generate a execution report from the procedures
##   found in the heml document provided as argument.
ifeq ($(word 1,$(MAKECMDGOALS)),procreport)
goalarg:=$(word 2,$(MAKECMDGOALS))

procreport: procreport.heml

HEMLTESTREPORT_STYLE?=$(DOCROOT)/procreport.xsl

.PHONY: procreport.heml
procreport.heml: $(goalarg)
	$(call absHemlTransformation,$(HEMLTESTREPORT_STYLE) )
	@$(ABS_PRINT_info) "Generated report template in: $@"

$(goalarg):
	:

endif

ifeq ($(filter +%,$(MAKECMDGOALS)),$(MAKECMDGOALS))
## - +<heml_doc_name>.<pdf|html>: force generation of a single heml document
ifeq ($(filter %.pdf,$(MAKECMDGOALS)),$(MAKECMDGOALS))
_ABS_FORCED_TARGET:=$(patsubst +%.pdf,$(TRDIR)/share/doc/$(APPNAME)/pdf/%.pdf,$(MAKECMDGOALS))
# tex/tdf case
# delete output tex and pdf file to force gereration with the next target below
_ABS_FORCE_SHELL:=$(shell rm -rf $(_ABS_FORCED_TARGET) $(patsubst +%.pdf,$(TRDIR)/share/doc/$(APPNAME)/tex/%.tex,$(MAKECMDGOALS)) ; echo "deleted")

# translate short target to full path target
#+%.pdf: $(TRDIR)/share/doc/$(APPNAME)/pdf/%.pdf
$(MAKECMDGOALS):
	echo $@
	@:

else
# html case
_ABS_FORCED_TARGET:=$(patsubst +%.html,$(TRDIR)/share/doc/$(APPNAME)/html/%.html,$(MAKECMDGOALS))
# delete html file to force gereration with the next target below
_ABS_FORCE_SHELL:=$(shell rm -rf $(_ABS_FORCED_TARGET))

endif
# translate short target to full path target
$(MAKECMDGOALS): $(_ABS_FORCED_TARGET)
	@:

endif
