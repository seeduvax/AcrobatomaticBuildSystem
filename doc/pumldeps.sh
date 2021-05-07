#!/bin/sh

if [ "$*" = "" ]
then
	exit 1
fi

catdeps() {
fgrep "$@" module.cfg | sed -e 's/:.*@/ /g' | while read srcFile startuml img endofline
do
	imgp=`dirname $srcFile`
	imgp=`echo $imgp/$img | sed -e 's:src/::g'`
	cat << EOF
\$(HTMLDIR)/$imgp: \$(patsubst src/%,\$(OBJDIR)/%.pumlgenerated,$srcFile)

PUMLGENIMGS+=\$(HTMLDIR)/$imgp

EOF
done
}

catdeps "@startuml" "$@"
catdeps "@startdot" "$@"
