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
cp -R test/resources/proj* $testDirectory

unset TTARGETDIR
unset TRDIR

doExit() {
    # The symlink over PRJROOT strangely makes pdflatex hangs when heml doc is generated
    # after this test, then remove the directory to make it run.
    rm $testDirectory/absws/abs-99.99.99
    exit $1
}

cd $testDirectory/projA
ARCH=NotALinux make pubdist
if [ $? -ne 0 ]; then
    echo "Error while executing make pubdist on projA"
    doExit 1
fi

cd $testDirectory/projB
ARCH=NotALinux make pubdist
if [ $? -ne 0 ]; then
    echo "Error while executing make pubdist on projB"
    doExit 2
fi

cd $testDirectory/projD
ARCH=NotALinux make pubdist
if [ $? -ne 0 ]; then
    echo "Error while executing make pubdist on projD"
    doExit 3
fi

cd $testDirectory/projC
ARCH=NotALinux make testbuild
if [ $? -ne 0 ]; then
    echo "Error while executing make on projC"
    doExit 4
fi

ARCH=NotALinux make distinstall
if [ $? -ne 0 ]; then
    echo "Error while executing make distinstall on projC"
    doExit 5
fi

tail -n +2 $testDirectory/projC/dist/flatten/projC-2.4.3d/import.mk > $testDirectory/projC/dist/flatten/projC-2.4.3d/import2.mk

function testFile {
    diff -q $1 $2
    if [ $? -ne 0 ]; then
        echo "Error: $1 not equal to $2"
        doExit 6
    fi
}
testFile $testDirectory/projC/dist/flatten/projC-2.4.3d/import2.mk $MODROOT/test/resources/expected/import2.mk

doExit 0
