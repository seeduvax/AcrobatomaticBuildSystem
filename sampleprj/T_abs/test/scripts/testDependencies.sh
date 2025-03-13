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

function testFileExists {
    if [ ! -f $1 ]; then
        echo "Error: File $1 doesn't exists"
        doExit 13
    fi
}

function testFile {
    diff -q $1 $2
    if [ $? -ne 0 ]; then
        echo "Error: $1 not equal to $2"
        doExit 6
    fi
}

cd $testDirectory/libtest
ARCH=NotALinux make pubdist ABS_LOG_LEVEL=debug
if [ $? -ne 0 ]; then
    echo "Error while executing make on libtest"
    doExit 11
fi

cd $testDirectory/testlib2
ARCH=NotALinux make pubdist ABS_LOG_LEVEL=debug
if [ $? -ne 0 ]; then
    echo "Error while executing make on testlib2"
    doExit 12
fi

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
projBOutDir=$testDirectory/projB/dist/flatten/projB-2.4.2d
projBObjDir=$projBOutDir/obj
# test extraction of sources from archives.
testFileExists $projBObjDir/cpplib3/extsrc/subdir2/source.cpp
testFileExists $projBObjDir/cpplib3/extsrc/subdir2/source2.cpp
testFileExists $projBObjDir/cpplib3/extsrc/source3.cpp
# test extraction of includes from archives
testFileExists $projBOutDir/include/projB/cpplib3/subdir/inc.h
testFileExists $projBOutDir/include/projB/cpplib3/subdir/inc2.h
testFileExists $projBOutDir/include/projB/cpplib3/inc3.hpp

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

ARCH=NotALinux make pubinstall ABS_LOG_LEVEL=debug
if [ $? -ne 0 ]; then
    echo "Error while executing make pubinstall on projC"
    doExit 5
fi
projCOutDir=$testDirectory/projC/dist/flatten/projC-2.4.3d
projCObjDir=$projCOutDir/obj
# test extraction of sources from archives.
testFileExists $projCObjDir/cpplib/extsrc/archive1/subdir2/source.cpp
testFileExists $projCObjDir/cpplib/extsrc/archive2/subdir2/source2.cpp
# test extraction of includes from archives
testFileExists $projCOutDir/include/projC/cpplib/archive1/subdir/inc.h
testFileExists $projCOutDir/include/projC/cpplib/archive2/subdir/inc2.h

tail -n +2 $testDirectory/projC/dist/flatten/projC-2.4.3d/import.mk > $testDirectory/projC/dist/flatten/projC-2.4.3d/import2.mk
tail -n +2 $testDirectory/projB/dist/flatten/projB-2.4.2d/import.mk > $testDirectory/projB/dist/flatten/projB-2.4.2d/import2.mk

testFileExists $testDirectory/repository/NotALinux/projA-1.4.2d.NotALinux.tar.gz
testFileExists $testDirectory/repository/NotALinux/projB/projB-2.4.2d.NotALinux.tar.gz
testFileExists $testDirectory/projC/dist/flatten/projC-2.4.3d/lib/libprojC_cpplib.a
testFileExists $testDirectory/projC/dist/flatten/projC-2.4.3d/lib/libprojC_cpplib.so

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
testFile $testDirectory/projC/dist/installed/etc/projB/aFile.txt $MODROOT/test/resources/expected/aFileB.txt

doExit 0
