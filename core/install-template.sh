#!/bin/sh

APPNAME=__appname__
VERSION=__version__
CHECKSUM=__checksum__
CHECKSUMCMD=md5sum
PREFIX=/opt/$APPNAME-$VERSION


THIS=$0
SKIP=`awk '/^__END_SCRIPT_TAG__$/ { print NR + 1; exit 0; }' "$THIS"`

UNTAR_ARGS="v"
TARGET=

help() {
cat << EOF
$1 <cmd> [args] <target>

  Available commands as <cmd> [args]:

    install : install application $APPNAME $VERSION
      target: (optional) installation path. Default installation path is
              $PREFIX

    extract : extract embedded tar gz archive as $APPNAME-$VERSION.bin.tar.gz
      target: (optional) arg : alternate target file

    options:
        --quiet: Hide the untar process 
        --nochecksum: disable checksum control (use to force install or extract even
          when checksum control failed).

    help : display help info

  Examples : 

    to install application to its default location just enter following command
      $1 install

    to extract embedded archive as archive.tar.gz :
      $1 extract archive.tar.gz
EOF
exit 0
}

checksum() {
    if [ "$CHECKSUM" != "" ]
    then
        CHECK=`$CHECKSUMCMD $1 | cut -f 1 -d ' '`
        if [ "$CHECK" != "$CHECKSUM" ]
        then
            echo "Error: possible file integrity issue, checksum not matching"
            echo "    expected: $CHECKSUM"
            echo "    found:    $CHECK"
            echo "  Use --nochecksum option to disable checksum control and force operations anyway (at your own risks)."
            exit 3
        fi
    fi
}

install() {
    if [ "$TARGET" != "" ]
    then
        PREFIX="$TARGET"
    fi
    echo "Welcome to $APPNAME $VERSION installation."
    # test that the directory not exists or doesn't contains no files.
    if [ -r "$PREFIX" -a ! -z "$(ls -A $PREFIX)" ]
    then
        echo "Warning: target directory already exists. Continue ? [y: Yes, N: (default)No, r: remove previous installation]"
        read rep
        if [ "$rep" = "r" -o "$rep" = "R" ]
        then
            # test we don't try to remove the / directory
            if [ "$PREFIX" = "/" -o "$PREFIX" = "" ]; then
                echo "Cannot remove data from $PREFIX/ !!!"
                exit 1
            else
                echo ""
                echo "#### Removing previous installation..."
                rm -rf "$PREFIX"/*
                rm -rf "$PREFIX"/.* 2> /dev/null # we silence errors for . and ..
                echo "#### Previous installation removed"
                echo ""
            fi
        elif [ "$rep" != "y" -a "$rep" != "Y" ]
        then
            exit 1
        fi
    else
        mkdir -p "$PREFIX" 
    fi

    if [ ! -w "$PREFIX" ]
    then
        echo "Can't create installation path. Check path or gain required write access."
        exit 2
    fi

    TEMPDIR="$PREFIX/abs-install.$$"
    mkdir -p "$TEMPDIR"
    echo ""
    echo "#### checking archive..."
    tail -n +$SKIP "$THIS" | checksum - || exit 3
    echo "#### Extracting files..."
    tail -n +$SKIP "$THIS" | tar $UNTAR_ARGS"xz" -C "$TEMPDIR"
    echo "#### Files extracted"
    echo ""
    mv "$TEMPDIR"/$APPNAME-$VERSION/* "$PREFIX"
    mv "$TEMPDIR"/$APPNAME-$VERSION/.* "$PREFIX" 2> /dev/null # we silence errors for . and ..
    rm -rf "$TEMPDIR"
    
    # fix tar extract preserving original uid/gid when extracting as root
    uid=`id -u`
    [ $uid -eq 0 ] && chown -R 0:0 "$PREFIX"

    # patch files with actual install path
    PATCHFILES="__post_install_patch_files__"
    for patch_file in $PATCHFILES
    do
        if [ -f "$PREFIX/$patch_file" ]; then
            abs_prefix=`readlink -f $PREFIX`
            [ -z "$abs_prefix" ] && abs_prefix=$PREFIX
            echo "Patching $PREFIX/$patch_file"
            sed -i "s~{INSTALL_PATH}~$abs_prefix~g" $PREFIX/$patch_file
        fi
    done
    postinstall_script="bin/postinstall_${APPNAME}.sh"
    [ ! -x "$PREFIX/${postinstall_script}" ] && postinstall_script="bin/postinstall.sh"

    if [ -x "$PREFIX/${postinstall_script}" ]
    then
        echo ""
        echo "#### Executing postinstall script: $postinstall_script"
        ( cd "$PREFIX" && exec "${postinstall_script}" "$APPNAME" "$VERSION" )
        echo "#### Executing postinstall script $postinstall_script ended"
        echo ""
    fi
    echo "Installation completed."
}

extract() {
    target=$APPNAME-$VERSION.bin.tar.gz
    if [ "$TARGET" != "" ]
    then
        target="$TARGET"
    fi
    if [ -f "$target" ]
    then
        echo "Warning: target file already exists. Continue (y/N) ?"
        read rep
        if [ "$rep" != "y" -a "$rep" != "Y" ]
        then
            exit 1
        fi
    fi
    tail -n +$SKIP "$THIS" > "$target"
    echo "Extraction completed."
    checksum $target
}


if [ $# -eq 0 ]
then
    help $0
fi

COMMAND=
case "$1" in
    install|extract) 
        COMMAND=$1
        ;;
    *)
        help $0
        ;;
esac

shift
while [ $# -ge 1 ]
do
    case "$1" in
        --nochecksum)
            CHECKSUM=""
            ;;
        --quiet)
            UNTAR_ARGS=""
            ;;
        *)
            # the last argument is the target if no match with anyother cases
            if [ $# = 1 ]; then
                TARGET=$1
            else
                echo "Unknown argument $1"
            fi
            ;;            
    esac
    shift
done
"$COMMAND"

exit 0
__END_SCRIPT_TAG__
