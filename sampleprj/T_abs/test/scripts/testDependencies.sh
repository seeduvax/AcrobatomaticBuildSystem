#!/bin/bash

source $(dirname $0)/initTest.sh testDependencies

expectedDir="$MODROOT/test/resources/expected"
executeMake pubdist libtest VERSION=2.0.0

executeMake pubdist projA
testLinked projA cppexe projA_cpplib

projAOutDir=$testDirectory/projA/dist/flatten/projA-1.4.2d
projAObjDir=$projAOutDir/obj
testFile $projAObjDir/cppexe/moddeps.mk $expectedDir/projA_cppexe_moddeps.mk
tail -n +2 $projAOutDir/import.mk > $projAOutDir/import2.mk
testFile $projAOutDir/import2.mk $expectedDir/projA_import2.mk

executeMake pubdist projB
testLinked projB cpplib projA_cpplib test
testLinked projB cpplib2 projA_cpplib test3 testlib-dashed

projBOutDir=$testDirectory/projB/dist/flatten/projB-2.4.2d
projBObjDir=$projBOutDir/obj
# test extraction of sources from archives.
echo "Test extracted sources..."
testFileExists $projBObjDir/cpplib3/extsrc/subdir2/source.cpp
testFileExists $projBObjDir/cpplib3/extsrc/subdir2/source2.cpp
testFileExists $projBObjDir/cpplib3/extsrc/source3.cpp
# test extraction of includes from archives
testFileExists $projBOutDir/include/projB/cpplib3/subdir/inc.h
testFileExists $projBOutDir/include/projB/cpplib3/subdir/inc2.h
testFileExists $projBOutDir/include/projB/cpplib3/inc3.hpp

tail -n +2 $testDirectory/projB/dist/flatten/projB-2.4.2d/import.mk > $testDirectory/projB/dist/flatten/projB-2.4.2d/import2.mk
testFile $testDirectory/projB/dist/flatten/projB-2.4.2d/import2.mk $expectedDir/projB_import2.mk

executeMake pubdist projD
executeMake testbuild projC
executeMake pubinstall projC

testNotImported projC libtest-1.0.0 libtest-2.0.0

projCOutDir=$testDirectory/projC/dist/flatten/projC-2.4.3d
projCObjDir=$projCOutDir/obj
# test extraction of sources from archives.
testFileExists $projCObjDir/cpplib/extsrc/archive1/subdir2/source.cpp
testFileExists $projCObjDir/cpplib/extsrc/archive2/subdir2/source2.cpp
# test extraction of includes from archives
testFileExists $projCOutDir/include/projC/cpplib/archive1/subdir/inc.h
testFileExists $projCOutDir/include/projC/cpplib/archive2/subdir/inc2.h

tail -n +2 $testDirectory/projC/dist/flatten/projC-2.4.3d/import.mk > $testDirectory/projC/dist/flatten/projC-2.4.3d/import2.mk
testFile $testDirectory/projC/dist/flatten/projC-2.4.3d/import2.mk $expectedDir/import2.mk

testFileExists $testDirectory/repository/NotALinux/projA-1.4.2d.NotALinux.tar.gz
testFileExists $testDirectory/repository/NotALinux/projB/projB-2.4.2d.NotALinux.tar.gz
testFileExists $testDirectory/projC/dist/flatten/projC-2.4.3d/lib/libprojC_cpplib.a
testFileExists $testDirectory/projC/dist/flatten/projC-2.4.3d/lib/libprojC_cpplib.so

binInstall="$testDirectory/projC/dist/projC-2.4.3d.NotALinux-install.bin"
if [ ! -f $binInstall ]; then
    echo "Error: Binary '$binInstall' not generated"
    doExit 7
fi
$binInstall install $testDirectory/projC/dist/installed

buildlog="$testDirectory/projC/dist/flatten/projC-2.4.3d/obj/build.log"
grep "Processing external" $buildlog | sed -E 's/.*> //g' > $buildlog.processed

testFile $buildlog.processed $expectedDir/projC_extmods.txt

testFileExists $testDirectory/projC/dist/installed/etc/aFile.txt
# test dependencies transitivity
testFileExists $testDirectory/projC/dist/installed/etc/projB/aFile.txt
# test presence of hidden files.
testFileExists $testDirectory/projC/dist/installed/etc/projB/.ImHidden

testFileExists $testDirectory/projC/dist/installed/etc/projA/aFile.txt

testFile $testDirectory/projC/dist/installed/etc/projB/aFile.txt $expectedDir/aFileB.txt

doExit 0
