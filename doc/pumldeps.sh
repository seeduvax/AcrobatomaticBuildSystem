#!/bin/sh

if [ "$*" = "" ]
then
	exit 1
fi

catdeps() {
echo "DDDDD: " "$@" >&2
fgrep "$@" module.cfg | sed -e 's/:.*@/ /g' | while read srcFile startuml img endofline
do
echo "DDD: " "$srcFile $startuml $img / $endofline" >&2
	cat << EOF
\$(HTMLDIR)/$img: \$(patsubst src/%,\$(OBJDIR)/%.pumlgenerated,$srcFile)

IMGS+=\$(HTMLDIR)/$img

EOF
done
}

catdeps "@startuml" "$@"
catdeps "@startdot" "$@"
