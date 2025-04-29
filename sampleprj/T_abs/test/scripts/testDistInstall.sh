#!/bin/bash

source $(dirname $0)/initTest.sh testDistInstall

expectedDir="$MODROOT/test/resources/expected"

executeMake distinstall projA
executeMake pubdist projA
executeMake distinstall projB
echo "Test publish with profiler flavor"
PROFILER=true executeMake pubinstall projB
testFileExists $testDirectory/repository/NotALinux/projB/projB-2.4.2d_tracy-0.9.1.NotALinux-install.bin

projBFlattenDir="$testDirectory/projB/dist/flatten/projB-2.4.2d_tracy-0.9.1"
tail -n +2 $projBFlattenDir/import.mk > $projBFlattenDir/import2.mk
testFile $projBFlattenDir/import2.mk $expectedDir/projB_tracy_import.mk

buildlog="$projBFlattenDir/obj/build.log"
grep "Processing external" $buildlog | sed -E 's/.*> //g' > $buildlog.processed
testFile $buildlog.processed $expectedDir/projB_tracy.processed

head -n 20 $testDirectory/repository/NotALinux/projB/projB-2.4.2d_tracy-0.9.1.NotALinux-install.bin | \
    sed 's/CHECKSUM=.*/CHECKSUM=/g' > $testDirectory/projB/headDistProjB.txt
testFile $testDirectory/projB/headDistProjB.txt $expectedDir/headDistProjB.txt

executeMake pubdist clang
executeMake pubdist runtime-clang
executeMake clean projB
BUILDCHAIN=clang-13 executeMake distinstall projB
testFileExists $testDirectory/projB/dist/projB-2.4.2d_clang-13.NotALinux-install.bin

projBFlattenDir="$testDirectory/projB/dist/flatten/projB-2.4.2d_clang-13"
tail -n +2 $projBFlattenDir/import.mk > $projBFlattenDir/import2.mk
testFile $projBFlattenDir/import2.mk $expectedDir/projB_clang_import.mk
buildlog="$projBFlattenDir/obj/build.log"
grep "Processing external" $buildlog | sed -E 's/.*> //g' > $buildlog.processed
testFile $buildlog.processed $expectedDir/projB_clang.processed

doExit 0
