#!/bin/bash

source $(dirname $0)/initTest.sh testPatches

cd $testDirectory
executeMake pubdist libtest
executeMake pubdist testlib2

executeMake pubdist projA
executeMake all projB

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
cd projB
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
