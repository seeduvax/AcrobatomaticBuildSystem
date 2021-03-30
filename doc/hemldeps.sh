#!/bin/sh

if [ "$*" = "" ]
then
	exit 1
fi

IFS=": "
fgrep "@startum" $* | while read srcFile staruml img
do
	cat << EOF
\$(OBJDIR)/$img: \$(patsubst src/%.heml,\$(OBJDIR)/%.pumlgenerated,$srcFile)

\$(patsubst src/%.heml,\$(HTMLDIR)/%.html,$srcFile): \$(OBJDIR)/$img

\$(patsubst src/%.heml,\$(PDFDIR)/%.pdf,$srcFile): \$(OBJDIR)/$img

EOF
done
