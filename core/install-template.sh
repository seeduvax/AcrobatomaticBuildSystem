#!/bin/sh

APPNAME=__appname__
VERSION=__version__
PREFIX=/opt/$APPNAME-$VERSION

THIS=$0
SKIP=`awk '/^__END_SCRIPT_TAG__$/ { print NR + 1; exit 0; }' "$THIS"`

UNTAR_ARGS="v"
TARGET=

help() {
cat << EOF
$1 <cmd> [args] <target>

  Available commands as <cmd> :

    install : install application $APPNAME $VERSION
      args:
         --quiet: Hide the untar process 
      target: (optional) installation path. Default installation path is
              $PREFIX

    extract : extract embedded tar gz archive as $APPNAME-$VERSION.bin.tar.gz
      target: (optional) arg : alternate target file

    help : display help info

  Examples : 

    to install application to its default location just enter following command
      $1 install

    to extract embedded archive as archive.tar.gz :
      $1 extract archive.tar.gz
EOF
exit 0
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
		    echo ""
		    echo "#### Removing previous installation..."
		    rm -rf "$PREFIX"/*
            rm -rf "$PREFIX"/.* 2> /dev/null # we silence errors for . and ..
            echo "#### Previous installation removed"
            echo ""
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

	TEMPDIR="$PREFIX/bs-install.$$"
	mkdir -p "$TEMPDIR"
    echo ""
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

    # update .env file with actual install path
    env_file=$PREFIX/.env
    if [ -f "$env_file" ]; then
        abs_prefix=`readlink -f $PREFIX`
        mv $env_file ${env_file}.bak
        [ -z "$abs_prefix" ] && abs_prefix=$PREFIX
        echo "INSTALL_DIR=$abs_prefix" > $env_file
        cat ${env_file}.bak >> ${env_file}
        rm -f ${env_file}.bak
    fi
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
        --quiet)
            UNTAR_ARGS=""
            shift
            ;;
        *)
            # the last argument is the target if no match with anyother cases
            if [ $# = 1 ]; then
                TARGET=$1
            else
                echo "Unknown argument $1"
            fi
            shift
            ;;            
    esac
done
"$COMMAND"

exit 0
__END_SCRIPT_TAG__
