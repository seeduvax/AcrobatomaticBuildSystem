#!/bin/sh

if [ "$*" = "" ]
then
	exit 1
fi

IFS=": "
fgrep "@startuml" $* module.cfg | while read srcFile staruml img
do
	cat << EOF
\$(HTMLDIR)/$img: \$(patsubst src/%.heml,\$(OBJDIR)/%.pumlgenerated,$srcFile)

\$(patsubst src/%.heml,\$(HTMLDIR)/%.html,$srcFile): \$(HTMLDIR)/$img

\$(patsubst src/%.heml,\$(PDFDIR)/%.pdf,$srcFile): \$(HTMLDIR)/$img

EOF
done
