#!/bin/bash

if [ ! -d $TTARGETDIR ]; then
    echo "No TTARGETDIR variable defined"
    exit 1
fi

testDirectory=$TTARGETDIR/testDependencies
PRJROOT=`pwd`/../../
rm -rf $testDirectory
mkdir -p $testDirectory
mkdir -p $testDirectory/absws
mkdir -p $testDirectory/repository/NotALinux
echo "Copy resources to $testDirectory"

ln -s $PRJROOT $testDirectory/absws/abs-99.99.99
cp -R test/resources/proj* $testDirectory

unset TTARGETDIR
unset TRDIR

cd $testDirectory/projA
ARCH=NotALinux make pubdist
if [ $? -ne 0 ]; then
    echo "Error while executing make pubdist on projA"
    exit 1
fi

cd $testDirectory/projB
ARCH=NotALinux make pubdist
if [ $? -ne 0 ]; then
    echo "Error while executing make pubdist on projB"
    exit 1
fi

cd $testDirectory/projD
ARCH=NotALinux make pubdist
if [ $? -ne 0 ]; then
    echo "Error while executing make pubdist on projD"
    exit 1
fi

cd $testDirectory/projC
ARCH=NotALinux make testbuild
if [ $? -ne 0 ]; then
    echo "Error while executing make on projC"
    exit 1
fi

ARCH=NotALinux make distinstall
if [ $? -ne 0 ]; then
    echo "Error while executing make distinstall on projC"
    exit 1
fi

exit 0