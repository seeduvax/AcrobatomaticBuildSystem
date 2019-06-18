#!/bin/sh

APP=__app__
VERSION=__version__
PKVERSION=__kversion__
KVERSION=`uname -r`
PREFIX="/"

THIS=$0
SKIP=`awk '/^__END_SCRIPT_TAG__$/ { print NR + 1; exit 0; }' "$THIS"` 

help() {
cat << EOF
$1 <cmd> [cmd args]

  Available commands as <cmd> :

    install : install kernel module package $APP $VERSION
      optionnal arg : installation prefix. Default is $PREFIX

    extract : extract embedded tar gz archive as $APP-$VERSION-$PKVERSION.bin.tar.gz
      optionnal arg : alternate target file

    list : list modules

    activate : activate a kernel module
      mandatory arg : module name

    help : display help info
EOF
exit 0
}

install() {
	if [ "$PKVERSION" != "$KVERSION" ]
	then
		echo "Warning! current kernel version ($KVERSION) doesn't match package target version ($PKVERSION)."
		echo "Continue (y/n)?."
		read rep
		if [ "$rep" != "y" -a "$rep" != "Y" ]
		then
			exit 1
		fi
	fi
	if [ $# -eq 1 ]
	then
		PREFIX="$1"
	fi
	echo "Welcome to $APP $VERSION installation."
	if [ -r "$PREFIX" ]
	then
		echo "Warning: target directory already exists. Continue (y/n) ?"
		read rep
		if [ "$rep" != "y" -a "$rep" != "Y" ]
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

	mkdir -p "$PREFIX/lib/modules/$PKVERSION/drast"
	tail -n +$SKIP "$THIS" | tar -xvz -C "$PREFIX/lib/modules/$PKVERSION/drast" --strip-components=2 lib/modules 
	mkdir -p "$PREFIX/etc/init.d"
	tail -n +$SKIP "$THIS" | tar -xvz -C "$PREFIX/etc/init.d" --strip-components=2 etc/init.d
	mkdir -p "$PREFIX/etc/drast"
	tail -n +$SKIP "$THIS" | tar -xvz -C "$PREFIX/etc/drast" --strip-components=2 --keep-old-files etc/drast
	depmod -a

	echo "File Installation done. Restart or reload related services and modules to complete installation."
}

extract() {
	target=$APP-$VERSION-$PKVERSION.bin.tar.gz
	if [ $# -eq 1 ]
	then
		target="$1"
	fi
	if [ -f "$target" ]
	then
		echo "Warning: target file already exists. Continue (y/n)?"
		read rep
		if [ "$rep" != "y" -a "$rep" != "Y" ]
		then
			exit 1
		fi
	fi
	tail -n +$SKIP "$THIS" > "$target"
	echo "Extraction completed."
}

list() {
	tail -n +$SKIP "$THIS" | tar -tz etc/init.d | sed 's/etc\/init\.d\/\(.*\)/\1/g'
}

activate() {
	if [ $# -eq 1 ]; then
		moduleName=$1
		echo "Activation of the module $moduleName"
		if [ -f /etc/init.d/$moduleName ]; then 
			chmod 755 /etc/init.d/$moduleName
			which chkconfig && chkconfig --add $moduleName
			which update-rc.d && update-rc.d $moduleName defaults
			echo "Starting device..."
			/etc/init.d/$moduleName start
			echo "Activation finished"
		else
			echo "Cannot find the file /etc/init.d/$moduleName"
		fi
	fi
}

if [ $# -eq 0 ]
then
	help $0
fi

case "$1" in
	install|extract|list|activate) 
		"$@"
		;;
	*)
		help $0
		;;
esac

exit 0
__END_SCRIPT_TAG__
