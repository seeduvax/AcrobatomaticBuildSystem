#!/bin/bash

if [ ! -d $TTARGETDIR ]; then
    echo "No TTARGETDIR variable defined"
    exit 1
fi

testDirectory=$TTARGETDIR/testPatches
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
ARCH=NotALinux make ABS_LOG_LEVEL=debug  MODE=debug
if [ $? -ne 0 ]; then
    echo "Error while executing make on projB"
    doExit 2
fi
projBOutDir=$testDirectory/projB/build/NotALinux/debug
projBObjDir=$projBOutDir/obj
# test extraction of sources from archives.
testFileExists $projBObjDir/cpplib3/extsrc/subdir2/source.cpp
testFileExists $projBObjDir/cpplib3/extsrc/subdir2/source2.cpp
testFileExists $projBObjDir/cpplib3/extsrc/source3.cpp
# test extraction of includes from archives
testFileExists $projBOutDir/include/projB/cpplib3/subdir/inc.h
testFileExists $projBOutDir/include/projB/cpplib3/subdir/inc2.h
testFileExists $projBOutDir/include/projB/cpplib3/inc3.hpp

# test patches generation
echo "#### Launch generation patches"
projBOUtPatchesDir=$testDirectory/projBPatches
ARCH=NotALinux make generatePatches -C cpplib3 ARCHSRC_GENE_PATCHES_OUT=$projBOUtPatchesDir MODE=debug
if [ $? -ne 0 ]; then
    echo "Error while executing make generatePatches on projB"
    doExit 3
fi
testFileExists $projBOUtPatchesDir/subdir2/source2.cpp.patch
testFileExists $projBOUtPatchesDir/subdir/inc.h.patch

function removeDateFromPatch {
    head -n 2 $1 | sed 's/\t.*//g' > $2
    tail -n +3 $1 >> $2
}

removeDateFromPatch cpplib3/patches/subdir2/source2.cpp.patch $projBOUtPatchesDir/subdir2/source2.expected
removeDateFromPatch cpplib3/patches/subdir/inc.h.patch $projBOUtPatchesDir/subdir/inc.expected
removeDateFromPatch $projBOUtPatchesDir/subdir2/source2.cpp.patch $projBOUtPatchesDir/subdir2/source2.generated
removeDateFromPatch $projBOUtPatchesDir/subdir/inc.h.patch $projBOUtPatchesDir/subdir/inc.generated

testFile $projBOUtPatchesDir/subdir2/source2.expected $projBOUtPatchesDir/subdir2/source2.generated
testFile $projBOUtPatchesDir/subdir/inc.expected $projBOUtPatchesDir/subdir/inc.generated

doExit 0
