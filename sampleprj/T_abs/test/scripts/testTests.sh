#!/bin/bash

source $(dirname $0)/initTest.sh testTests

executeMake pubdist projA
testLinked projA cppexe projA_cpplib

executeMake testbuild projB
testLinkedInBuild projB cpplib projA_cpplib test
testLinkedInBuild projB cpplib2 projA_cpplib test3 testlib-dashed
testLinkedInBuild projB t_cpplib2 cppunit projA_cpplib projB_cpplib2 projB_cpplib3 test3 testlib-dashed

executeMake newtest projB/cpplib T=Toto
createdFile=$testDirectory/projB/cpplib/test/TestToto.cpp
testFileExists $createdFile
sed -i 's/Copyright (.*) eduvax/Copyright 2025 eduvax/g' $createdFile
testFile $MODROOT/test/resources/expected/TestToto.cpp $createdFile

testFile $MODROOT/test/resources/expected/TestExample.h $testDirectory/projB/build/NotALinux/$MODE/obj/cpplib2/test

doExit 0
