BASEDIR		:= ~/cross-lfs-book
DUMPDIR		:= ~/cross-lfs-commands
DLLISTDIR	:= ~/cross-lfs-dllist
CHUNK_QUIET	:= 1
XSLROOTDIR	:= /usr/share/xml/docbook/xsl-stylesheets-1.69.1

S		:= -

ARCHS		:= x86 x86_64 x86_64-64 sparc sparc64 sparc64-64 mips mips64 mips64-64 ppc ppc64 alpha

ARCHS_HTML	:= $(ARCHS:%=%$(S)html)
ARCHS_NOCHUNKS	:= $(ARCHS:%=%$(S)nochunks)
ARCHS_PDF	:= $(ARCHS:%=%$(S)pdf)
ARCHS_TEXT	:= $(ARCHS:%=%$(S)text)
ARCHS_VALIDATE	:= $(ARCHS:%=%$(S)validate)
ARCHS_TROUBLE	:= $(ARCHS:%=%$(S)trouble)
ARCHS_DUMP	:= $(ARCHS:%=%$(S)dump)
ARCHS_DLLIST	:= $(ARCHS:%=%$(S)dllist)

.PHONY: lfs tidy render titlepage $(ARCHS_HTML) nochunks $(ARCHS_NOCHUNKS) pdf $(ARCHS_PDF) text $(ARCHS_TEXT) validate $(ARCHS_VALIDATE) trouble $(ARCHS_TROUBLE) dump-commands $(ARCHS_DUMP) download-list $(ARCHS_DLLIST)

lfs: render tidy

ifeq ($(shell which tidy >/dev/null 2>&1 && echo yes),yes)
tidy:
	@echo Running tidy on the created HTML
	@for filename in `find $(BASEDIR) -name "*.html"`; do \
	  tidy -config tidy.conf $$filename; \
	  true; \
	  sh obfuscate.sh $$filename; \
	  sed -i -e "s@text/html@application/xhtml+xml@g" $$filename; \
	done;
else
tidy:
	@echo Tidy is not installed on this system
endif

render: $(ARCHS_HTML) titlepage

titlepage:
	@xsltproc --nonet --output $(BASEDIR)/index.html $(PWD)/stylesheets/top-index.xsl $(PWD)/index.xml

$(ARCHS_HTML): override html_arch = $(@:%$(S)html=%)
$(ARCHS_HTML):
	@echo "Rendering HTML of $(html_arch)..."
	@xsltproc --xinclude --nonet -stringparam profile.condition html -stringparam chunk.quietly $(CHUNK_QUIET) -stringparam base.dir $(BASEDIR)/$(html_arch)/ $(PWD)/stylesheets/lfs-chunked.xsl $(PWD)/$(html_arch)-index.xml
	@mkdir -p $(BASEDIR)/$(html_arch)/stylesheets
	@cp $(PWD)/stylesheets/*.css $(BASEDIR)/$(html_arch)/stylesheets
	@sed -i -e "s@../stylesheets@stylesheets@g" $(BASEDIR)/$(html_arch)/*.html
	@mkdir -p $(BASEDIR)/$(html_arch)/images
	@cp $(XSLROOTDIR)/images/*.png $(BASEDIR)/$(html_arch)/images
	@sed -i -e "s@../images@images@g" $(BASEDIR)/$(html_arch)/*.html

nochunks: $(ARCHS_NOCHUNKS) tidy

$(ARCHS_NOCHUNKS): override nochunk_arch = $(@:%$(S)nochunks=%)
$(ARCHS_NOCHUNKS):
	@echo "Rendering Single File HTML of $(nochunk_arch)..."
	@xsltproc --xinclude --nonet -stringparam profile.condition html --output $(BASEDIR)/CLFS-BOOK-$(nochunk_arch).html $(PWD)/stylesheets/lfs-nochunks.xsl $(nochunk_arch)-index.xml

pdf: $(ARCHS_PDF)

$(ARCHS_PDF): override pdf_arch =  $(@:%$(S)pdf=%)
$(ARCHS_PDF):
	@echo "Rendering PDF of $(pdf_arch)..."
	@xsltproc --xinclude --nonet --output $(BASEDIR)/clfs-$(pdf_arch)-pdf.fo $(PWD)/stylesheets/lfs-pdf.xsl $(pdf_arch)-index.xml
	@sed -i -e "s/inherit/all/" $(BASEDIR)/clfs-$(pdf_arch)-pdf.fo
	@fop.sh -q -fo $(BASEDIR)/clfs-$(pdf_arch)-pdf.fo -pdf $(BASEDIR)/CLFS-BOOK-$(pdf_arch).pdf
	@rm $(BASEDIR)/clfs-$(pdf_arch)-pdf.fo

text: $(ARCHS_TEXT)

$(ARCHS_TEXT): override text_arch =  $(@:%$(S)text=%)
$(ARCHS_TEXT):
	@echo "Rendering Text of $(text_arch)..."
	@xsltproc --xinclude --nonet --output $(BASEDIR)/clfs-$(text_arch)-text.fo $(PWD)/stylesheets/lfs-pdf.xsl $(text_arch)-index.xml
	@sed -i -e "s/inherit/all/" $(BASEDIR)/clfs-$(text_arch)-text.fo ; \
	@fop.sh -q -fo $(BASEDIR)/clfs-$(text_arch)-text.fo -txt $(BASEDIR)/CLFS-BOOK-$(text_arch).txt ; \
	@rm $(BASEDIR)/clfs-$(text_arch)-text.fo

validate: $(ARCHS_VALIDATE)

$(ARCHS_VALIDATE): override validate_arch =  $(@:%$(S)validate=%)
$(ARCHS_VALIDATE):
	@echo "Validating $(validate_arch)..."
	@xmllint --xinclude --noout --nonet --postvalid $(PWD)/$(validate_arch)-index.xml

trouble: $(ARCHS_TROUBLE)

$(ARCHS_TROUBLE): override trouble_arch =  $(@:%$(S)trouble=%)
$(ARCHS_TROUBLE):
	@echo "Troubleshooting $(trouble_arch)..."
	@xmllint --xinclude --nonet --postvalid $(PWD)/$(trouble_arch)-index.xml > /tmp/dump-$(trouble_arch)
	@xmllint --xinclude --noout --nonet --valid /tmp/dump-$(trouble_arch)
	@echo "You can now look at /tmp/dump-$(trouble_arch) to see the errors"

dump-commands: $(ARCHS_DUMP)

$(ARCHS_DUMP): override dump_arch =  $(@:%$(S)dump=%)
$(ARCHS_DUMP):
	@echo "Extracting commands from $(dump_arch)..."
	@xsltproc --xinclude --nonet --output $(DUMPDIR)/$(dump_arch)/ $(PWD)/stylesheets/dump-commands.xsl $(dump_arch)-index.xml

download-list: $(ARCHS_DLLIST)

$(ARCHS_DLLIST): override dllist_arch = $(@:%$(S)dllist=%)
$(ARCHS_DLLIST):
	@echo "Creating download list for $(dllist_arch)..."
	@xsltproc --xinclude --nonet --output $(DLLISTDIR)/$(dllist_arch).dl.list $(PWD)/stylesheets/wget.xsl $(dllist_arch)-index.xml

help:
	@echo "HTML Targets"
	@echo -e "  \e[0;32mlfs tidy render titlepage \e[0;34m$(ARCHS_HTML)\e[0;0m"
	@echo
	@echo "NoChunks Targets"
	@echo -e "  \e[0;32mnochunks tidy \e[0;34m$(ARCHS_NOCHUNKS)\e[0;0m"
	@echo
	@echo "PDF Targets"
	@echo -e "  \e[0;32mpdf \e[0;34m$(ARCHS_PDF)\e[0;0m"
	@echo
	@echo "Text Targets"
	@echo -e "  \e[0;32mtext \e[0;34m$(ARCHS_TEXT)\e[0;0m"
	@echo
	@echo "Validate Targets"
	@echo -e "  \e[0;32mvalidate \e[0;34m$(ARCHS_VALIDATE)\e[0;0m"
	@echo
	@echo "Trouble Targets"
	@echo -e "  \e[0;32mtrouble \e[0;34m$(ARCHS_TROUBLE)\e[0;0m"
	@echo
	@echo "Dump-Commands Targets"
	@echo -e "  \e[0;32mdump-commands \e[0;34m$(ARCHS_DUMP)\e[0;0m"
	@echo
	@echo "Download-List Targets"
	@echo -e "  \e[0;32mdownload-list \e[0;34m$(ARCHS_DLLIST)\e[0;0m"
