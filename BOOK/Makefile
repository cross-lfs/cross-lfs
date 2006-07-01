BASEDIR=~/cross-lfs-book
DUMPDIR=~/cross-lfs-commands
DLLISTDIR=~/cross-lfs-dllist
CHUNK_QUIET=1
XSLROOTDIR=/usr/share/xml/docbook/xsl-stylesheets-1.69.1
ARCH=x86 x86_64 x86_64-64 sparc sparc64 sparc64-64 mips mips64 mips64-64 ppc ppc64 alpha

# HTML Rendering Chunked
define HTML_RENDER
	echo "Rendering HTML of $$arch..." ; \
	xsltproc --xinclude --nonet -stringparam profile.condition html \
	  -stringparam chunk.quietly $(CHUNK_QUIET) -stringparam base.dir $(BASEDIR)/$$arch/ \
	  $(PWD)/stylesheets/lfs-chunked.xsl $(PWD)/$$arch-index.xml ; \
	mkdir -p $(BASEDIR)/$$arch/stylesheets ; \
	cp $(PWD)/stylesheets/*.css $(BASEDIR)/$$arch/stylesheets ; \
	cd $(BASEDIR)/$$arch/; sed -i -e "s@../stylesheets@stylesheets@g" *.html ; \
	mkdir -p $(BASEDIR)/$$arch/images ; \
	cp $(XSLROOTDIR)/images/*.png $(BASEDIR)/$$arch/images ; \
	cd $(BASEDIR)/$$arch/; sed -i -e "s@../images@images@g" *.html
endef

# HTML Rendering No Chunks
define HTML_RENDER2
	echo "Rendering Single File HTML of $$arch..." ; \
	xsltproc --xinclude --nonet -stringparam profile.condition html \
	   --output $(BASEDIR)/CLFS-BOOK-$$arch.html \
	   $(PWD)/stylesheets/lfs-nochunks.xsl $$arch-index.xml
endef

# PDF Rendering
define PDF_RENDER
	echo "Rendering PDF of $$arch..." ; \
        xsltproc --xinclude --nonet --output $(BASEDIR)/lfs-pdf.fo \
                $(PWD)/stylesheets/lfs-pdf.xsl $$arch-index.xml ; \
        sed -i -e "s/inherit/all/" $(BASEDIR)/lfs-pdf.fo ; \
        fop.sh -q $(BASEDIR)/lfs-pdf.fo -pdf $(BASEDIR)/CLFS-BOOK-$$arch.pdf ; \
        rm $(BASEDIR)/lfs-pdf.fo
endef

# Plain Text Rendering
define TEXT_RENDER
        echo "Rendering Text of $$arch..." ; \
        xsltproc --xinclude --nonet --output $(BASEDIR)/lfs-pdf.fo \
                $(PWD)/stylesheets/lfs-pdf.xsl $$arch-index.xml ; \
        sed -i -e "s/inherit/all/" $(BASEDIR)/lfs-pdf.fo ; \
        fop.sh $(BASEDIR)/lfs-pdf.fo -txt $(BASEDIR)/CLFS-BOOK-$$arch.txt ; \
        rm $(BASEDIR)/lfs-pdf.fo
endef

# Validation
define VALIDATE
	echo "Validating $$arch..." ; \
        xmllint --xinclude --noout --nonet --postvalid $(PWD)/$$arch-index.xml
endef

# TroubleShoot
define TROUBLE
	echo "Troubleshooting $$arch..." ; \
        xmllint --xinclude --nonet --postvalid $(PWD)/$$arch-index.xml > /tmp/dump-$$arch ; \
	xmllint --xinclude --noout --nonet --valid /tmp/dump-$$arch ; \
	echo "You can now look at /tmp/dump-$$arch to see the errors"
endef

# Dump commands
define DUMP
	echo "Extracting commands from $$arch..." ; \
	xsltproc --xinclude --nonet --output $(DUMPDIR)/$$arch/ \
	   $(PWD)/stylesheets/dump-commands.xsl $$arch-index.xml
endef

# Get commands
define DLLIST
	echo "Creating download list for $$arch..." ; \
	xsltproc --xinclude --nonet --output $(DLLISTDIR)/$$arch.dl.list \
	   $(PWD)/stylesheets/wget.xsl $$arch-index.xml
endef

clfs: toplevel render common

toplevel:
	@xsltproc --nonet --output $(BASEDIR)/index.html $(PWD)/stylesheets/top-index.xsl $(PWD)/index.xml

render:
	@for arch in $(ARCH) ; do \
	$(HTML_RENDER) ; \
	done

common:
	@for filename in `find $(BASEDIR) -name "*.html"`; do \
	  tidy -config tidy.conf $$filename; \
	  true; \
	  sh obfuscate.sh $$filename; \
	  sed -i -e "s@text/html@application/xhtml+xml@g" $$filename; \
	done;

nochunks: nochunk_render common

nochunk_render:

	@for arch in $(ARCH) ; do \
	$(HTML_RENDER2) ; \
	done

pdf:
	@for arch in $(ARCH) ; do \
	$(PDF_RENDER) ; \
	done

text:
	@for arch in $(ARCH) ; do \
	$(TEXT_RENDER) ; \
	done

validate:
	@for arch in $(ARCH) ; do \
	$(VALIDATE) ; \
	done

trouble:
	@for arch in $(ARCH) ; do \
	$(TROUBLE) ; \
	done

dump-commands:
	@for arch in $(ARCH) ; do \
	$(DUMP) ; \
	done

download-list:
	@for arch in $(ARCH) ; do \
	$(DLLIST) ; \
	done

target-list:
	@printf "%-15s %-10s\n" "Architecture" "Build Type" ;\
	for arch in $(ARCH) ; do \
	MULTILIB=0 ;\
	PURE64=0 ;\
	TEST="`echo $$arch | grep -c -e '-64'`" ;\
	if [ "$$TEST" = "1" ]; then \
		PURE64=1 ;\
	else \
		TEST="`echo $$arch | grep -c -e '64'`" ;\
		if [ "$$TEST" = "1" ]; then \
			MULTILIB=1 ;\
		fi; \
	fi; \
	if [ "$$PURE64" = "1" ]; then \
		printf "%-15s %-10s\n" $$arch "Pure 64" ;\
	else \
		if [ "$$MULTILIB" = "1" ]; then \
			printf "%-15s %-10s\n" $$arch "Multilib" ;\
		else \
			printf "%-15s %-10s\n" $$arch "Default" ;\
		fi; \
	fi; \
	done

help:
	@printf "%-25s %-20s\n" "Command" "Function"
	@printf "%-25s %-20s\n" "make download-list" "Create download file lists"
	@printf "%-25s %-20s\n" "make dump-commands" "Dump all the commands from the book"
	@printf "%-25s %-20s\n" "make clfs" "Make the standard multilib page book"
	@printf "%-25s %-20s\n" "make nochunks" "Make single html file book"
	@printf "%-25s %-20s\n" "make pdf" "Make pdf copy of the book"
	@printf "%-25s %-20s\n" "make target-list" "Get List of Architecture targets"
	@printf "%-25s %-20s\n" "make test" "Make a text copy of the book"
	@printf "%-25s %-20s\n" "make trouble" "Make a copy tha's easy to troubleshoot"
	@printf "%-25s %-20s\n" "make validate" "Run book validation"

.PHONY: clfs toplevel common render nochunks nochunk_render pdf text validate trouble dump-commands download-list \
	target-list help
