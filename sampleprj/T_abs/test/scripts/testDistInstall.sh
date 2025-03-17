#!/bin/bash

source $(dirname $0)/initTest.sh testDistInstall

cd $testDirectory
executeMake pubdist libtest
executeMake pubdist testlib-dashed

executeMake distinstall projA
executeMake pubdist projA
executeMake distinstall projB
echo "Test publish with profiler flavor"
PROFILER=true executeMake pubinstall projB
testFileExists $testDirectory/repository/NotALinux/projB/projB-2.4.2d_tracy-0.9.1.NotALinux-install.bin

head -n 20 $testDirectory/repository/NotALinux/projB/projB-2.4.2d_tracy-0.9.1.NotALinux-install.bin | \
    sed 's/CHECKSUM=.*/CHECKSUM=/g' > $testDirectory/projB/headDistProjB.txt
testFile $testDirectory/projB/headDistProjB.txt $MODROOT/test/resources/expected/headDistProjB.txt
doExit 0
