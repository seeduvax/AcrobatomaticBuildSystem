#!/bin/bash

source $(dirname $0)/initTest.sh testDistInstall

executeMake distinstall projA
executeMake pubdist projA
executeMake distinstall projB
echo "Test publish with profiler flavor"
PROFILER=true executeMake pubinstall projB
testFileExists $testDirectory/repository/NotALinux/projB/projB-2.4.2d_tracy-0.9.1.NotALinux-install.bin

tail -n +2 $testDirectory/projB/dist/flatten/projB-2.4.2d_tracy-0.9.1/import.mk > $testDirectory/projB/dist/flatten/projB-2.4.2d_tracy-0.9.1/import2.mk
testFile $testDirectory/projB/dist/flatten/projB-2.4.2d_tracy-0.9.1/import2.mk $MODROOT/test/resources/expected/projB_tracy_import.mk

head -n 20 $testDirectory/repository/NotALinux/projB/projB-2.4.2d_tracy-0.9.1.NotALinux-install.bin | \
    sed 's/CHECKSUM=.*/CHECKSUM=/g' > $testDirectory/projB/headDistProjB.txt
testFile $testDirectory/projB/headDistProjB.txt $MODROOT/test/resources/expected/headDistProjB.txt

executeMake pubdist clang
executeMake pubdist runtime-clang
executeMake clean projB
BUILDCHAIN=clang-13 executeMake distinstall projB
testFileExists $testDirectory/projB/dist/projB-2.4.2d_clang-13.NotALinux-install.bin

tail -n +2 $testDirectory/projB/dist/flatten/projB-2.4.2d_clang-13/import.mk > $testDirectory/projB/dist/flatten/projB-2.4.2d_clang-13/import2.mk
testFile $testDirectory/projB/dist/flatten/projB-2.4.2d_clang-13/import2.mk $MODROOT/test/resources/expected/projB_clang_import.mk

doExit 0
