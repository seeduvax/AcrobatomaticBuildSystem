#!/bin/bash

[ -z "${ABS_PRINT_debug}" ] && ABS_PRINT_debug="echo '[abs-debug]	'"
[ -z "${ABS_PRINT_info}" ] && ABS_PRINT_info="echo '[abs-info]	'"
[ -z "${ABS_PRINT_warning}" ] && ABS_PRINT_warning="echo '[abs-warning]	'"
[ -z "${ABS_PRINT_error}" ] && ABS_PRINT_error="echo '[abs-error]	'"

function read_deps() {
    dir=$1
    grep extlib_import_template ${dir}/import.mk | sed -e 's/^.*,\(.*\)))/\1/'
}

function display_graph() {
    tool=$1
    file=$2
    which $tool > /dev/null 2>&1
    [ $? -eq 0 ] && [ ! -z "$DISPLAY" ] && {
        $ABS_PRINT_info "*** Launching $tool to display it... Close $tool to continue building or hit Ctrl-C to discard"
        $tool $file
        exit 0
    }
}

[ -z "${APPNAME}"  ] || [ -z "${PRJROOT}" ] || [ -z "${EXTLIBDIR}" ] || [ -z "${VERSION}" ] && {
    $ABS_PRINT_error "Define MODNAME, EXTLIBDIR and USELIB env vars before calling dependency helper tool" >&2
    exit 1
}

dot_file=${EXTLIBDIR}/${APPNAME}_deps.dot
png_file=${EXTLIBDIR}/${APPNAME}_deps.png

# generate graph
echo "digraph deps {" > $dot_file

allLibs=""
for libdir in ${EXTLIBDIR}/*; do
    if [ ! -L $libdir -a -d $libdir ]; then
    	lib=`basename $libdir`
        case $lib in
            cppunit-*)
                ;;
            *)
	        allLibs="$allLibs $lib"
                ;;
        esac
        lib_deps=$(read_deps $libdir)
        if [ $? -eq 0 ]; then
            for dep in ${lib_deps}; do
                echo "\"$lib\" -> \"$dep\"" >> $dot_file
            done
        fi
    fi
done
for lib in $allLibs
do
    fgrep -q "$lib" ${PRJROOT}/app.cfg ${PRJROOT}/*/module.cfg
    if [ $? -eq 0 ]; then
        echo "\"$APPNAME-$VERSION\" -> \"$lib\"" >> $dot_file
    else
       # Dislay as unknown dep unused libs found in extlib
    	fgrep -q "> \"$lib\"" $dot_file
        if [ ! $? -eq 0 ]; then
            echo "\"???\" -> \"$lib\"" >> $dot_file
        fi
    fi
done

echo "}" >> $dot_file

dot -Tpng $dot_file > $png_file

printf "*** Dependency graph for ${MODNAME} generated in $dot_file"

[ -f $png_file ] && printf " (image in $png_file)"

echo

# try to display graph
# xdot
display_graph xdot $dot_file
# eyes of GNOME
display_graph eog $png_file
# fall back on default file viewer
display_graph xdg-open $png_file

$ABS_PRINT_warning "*** Did not find appropriate tool to display it, or no X server active, review it later"

exit 0
