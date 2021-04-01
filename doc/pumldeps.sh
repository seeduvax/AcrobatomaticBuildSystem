#!/bin/sh

if [ "$*" = "" ]
then
	exit 1
fi

IFS=": "
fgrep "@startuml" $* module.cfg | while read srcFile staruml img
do
	cat << EOF
\$(HTMLDIR)/$img: \$(patsubst src/%,\$(OBJDIR)/%.pumlgenerated,$srcFile)

IMGS+=\$(HTMLDIR)/$img

EOF
done
