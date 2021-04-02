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

IMGS+=\$(HTMLDIR)/$img

EOF
done
}

catdeps "@startuml" "$@"
catdeps "@startdot" "$@"
