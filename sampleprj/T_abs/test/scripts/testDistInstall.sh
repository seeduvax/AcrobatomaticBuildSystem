#!/bin/bash

source $(dirname $0)/initTest.sh testDistInstall

cd $testDirectory
executeMake pubdist libtest
executeMake pubdist testlib2

executeMake distinstall projA
executeMake pubdist projA
executeMake distinstall projB
echo "Test publish with profiler flavor"
PROFILER=true executeMake pubinstall projB
testFileExists $testDirectory/repository/NotALinux/projB/projB-2.4.2d_tracy-0.9.1.NotALinux-install.bin
doExit 0
