#!/bin/bash

source $(dirname $0)/initTest.sh testTests

executeMake pubdist projA
testLinked projA cppexe projA_cpplib

executeMake testbuild projB
testLinkedInBuild projB cpplib projA_cpplib test
testLinkedInBuild projB cpplib2 projA_cpplib testlib-dashed
testLinkedInBuild projB t_cpplib2 cppunit projA_cpplib projB_cpplib2 projB_cpplib3 testlib-dashed

testFile $MODROOT/test/resources/expected/TestExample.h $testDirectory/projB/build/NotALinux/$MODE/obj/cpplib2/test

doExit 0
