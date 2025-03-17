#!/bin/bash

source $(dirname $0)/initTest.sh testDependencies

cd $testDirectory
executeMake pubdist libtest
executeMake pubdist testlib-dashed

executeMake pubdist projA
testLinked projA cppexe projA_cpplib

executeMake pubdist projB
testLinked projB cpplib projA_cpplib test

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

executeMake pubdist projD
executeMake testbuild projC
executeMake pubinstall projC

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
