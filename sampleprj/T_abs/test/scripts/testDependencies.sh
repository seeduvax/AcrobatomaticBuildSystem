#!/bin/bash

if [ ! -d $TTARGETDIR ]; then
    echo "No TTARGETDIR variable defined"
    exit 1
fi

testDirectory=$TTARGETDIR/testDependencies
MODROOT=`pwd`
PRJROOT=$MODROOT/../../
chmod -R +w $testDirectory
rm -rf $testDirectory
mkdir -p $testDirectory
mkdir -p $testDirectory/absws
mkdir -p $testDirectory/repository/NotALinux
echo "Copy resources to $testDirectory"

ln -s $PRJROOT $testDirectory/absws/abs-99.99.99
cp -R test/resources/proj* test/resources/libtest test/resources/testlib2 $testDirectory

unset TTARGETDIR
unset TRDIR

doExit() {
    # The symlink over PRJROOT strangely makes pdflatex hangs when heml doc is generated
    # after this test, then remove the directory to make it run.
    rm $testDirectory/absws/abs-99.99.99
    exit $1
}

cd $testDirectory/libtest
make 
if [ $? -ne 0 ]; then
    echo "Error while executing make on libtest"
    doExit 11
fi
cp $testDirectory/libtest/build/*.tar.gz $testDirectory/repository/NotALinux/

cd $testDirectory/testlib2
make 
if [ $? -ne 0 ]; then
    echo "Error while executing make on testlib2"
    doExit 12
fi
cp $testDirectory/testlib2/build/*.tar.gz $testDirectory/repository/NotALinux/


cd $testDirectory/projA
ARCH=NotALinux make pubdist ABS_LOG_LEVEL=debug
if [ $? -ne 0 ]; then
    echo "Error while executing make pubdist on projA"
    doExit 1
fi

cd $testDirectory/projB
ARCH=NotALinux make pubdist ABS_LOG_LEVEL=debug
if [ $? -ne 0 ]; then
    echo "Error while executing make pubdist on projB"
    doExit 2
fi

cd $testDirectory/projD
ARCH=NotALinux make pubdist ABS_LOG_LEVEL=debug
if [ $? -ne 0 ]; then
    echo "Error while executing make pubdist on projD"
    doExit 3
fi

cd $testDirectory/projC
ARCH=NotALinux make testbuild ABS_LOG_LEVEL=debug
if [ $? -ne 0 ]; then
    echo "Error while executing make on projC"
    doExit 4
fi

ARCH=NotALinux make distinstall ABS_LOG_LEVEL=debug
if [ $? -ne 0 ]; then
    echo "Error while executing make distinstall on projC"
    doExit 5
fi

tail -n +2 $testDirectory/projC/dist/flatten/projC-2.4.3d/import.mk > $testDirectory/projC/dist/flatten/projC-2.4.3d/import2.mk
tail -n +2 $testDirectory/projB/dist/flatten/projB-2.4.2d/import.mk > $testDirectory/projB/dist/flatten/projB-2.4.2d/import2.mk

function testFile {
    diff -q $1 $2
    if [ $? -ne 0 ]; then
        echo "Error: $1 not equal to $2"
        doExit 6
    fi
}
testFile $testDirectory/projC/dist/flatten/projC-2.4.3d/import2.mk $MODROOT/test/resources/expected/import2.mk
testFile $testDirectory/projB/dist/flatten/projB-2.4.2d/import2.mk $MODROOT/test/resources/expected/projB_import2.mk

binInstall="$testDirectory/projC/dist/projC-2.4.3d.NotALinux-install.bin"
if [ ! -f $binInstall ]; then
    echo "Error: Binary '$binInstall' not generated"
    doExit 7
fi
$binInstall install $testDirectory/projC/dist/installed

testFile="$testDirectory/projC/dist/installed/etc/aFile.txt"
if [ ! -f $testFile ]; then
    echo "Error: File '$testFile' not published"
    doExit 8
fi

# test dependencies transitivity
testFile="$testDirectory/projC/dist/installed/etc/projB/aFile.txt"
if [ ! -f $testFile ]; then
    echo "Error: File '$testFile' not published"
    doExit 9
fi

testFile="$testDirectory/projC/dist/installed/etc/projA/aFile.txt"
if [ ! -f $testFile ]; then
    echo "Error: File '$testFile' not published"
    doExit 10
fi

doExit 0
