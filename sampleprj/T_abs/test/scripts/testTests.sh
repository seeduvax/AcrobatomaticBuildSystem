#!/bin/bash

source $(dirname $0)/initTest.sh testTests

executeMake pubdist projA
testLinked projA cppexe projA_cpplib

executeMake testbuild projB
testLinkedInBuild projB cpplib projA_cpplib test
testLinkedInBuild projB t_cpplib2 cppunit projB_cpplib2 projB_cpplib3

testFile $MODROOT/test/resources/expected/TestExample.h $testDirectory/projB/build/NotALinux/$MODE/obj/cpplib2/test

doExit 0
