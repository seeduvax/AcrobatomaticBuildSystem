#!/bin/bash

if [ ! -d $TTARGETDIR ]; then
    echo "No TTARGETDIR variable defined"
    exit 1
fi

testDirectory=$TTARGETDIR/testDistInstall
MODROOT=`pwd`
PRJROOT=$MODROOT/../../
chmod -R +w $testDirectory
rm -rf $testDirectory
mkdir -p $testDirectory
mkdir -p $testDirectory/absws
mkdir -p $testDirectory/repository/NotALinux
mkdir -p $testDirectory/repository/noarch
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
cp $testDirectory/libtest/build/*.tar.gz $testDirectory/repository/noarch/

cd $testDirectory/testlib2
make 
if [ $? -ne 0 ]; then
    echo "Error while executing make on testlib2"
    doExit 12
fi
cp $testDirectory/testlib2/build/*.tar.gz $testDirectory/repository/NotALinux/


cd $testDirectory/projA
ARCH=NotALinux make distinstall && ARCH=NotALinux make pubdist
if [ $? -ne 0 ]; then
    echo "Error while executing make distinstall on projA"
    doExit 1
fi

cd $testDirectory/projB
ARCH=NotALinux make distinstall
if [ $? -ne 0 ]; then
    echo "Error while executing make distinstall on projB"
    doExit 1
fi

doExit 0
