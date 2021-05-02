#!/bin/sh

if [ "$*" = "" ]
then
	exit 1
fi

catdeps() {
fgrep "$@" module.cfg | sed -e 's/:.*@/ /g' | while read srcFile startuml img endofline
do
	cat << EOF
\$(HTMLDIR)/$img: \$(patsubst src/%,\$(OBJDIR)/%.pumlgenerated,$srcFile)

PUMLGENIMGS+=\$(HTMLDIR)/$img
EOF
done
}

catdeps "@startuml" "$@"
catdeps "@startdot" "$@"
