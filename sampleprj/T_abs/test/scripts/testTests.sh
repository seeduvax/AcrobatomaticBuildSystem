#!/bin/bash

source $(dirname $0)/initTest.sh testTests

cd $testDirectory
executeMake pubdist libtest
executeMake pubdist testlib2

executeMake pubdist projA
testLinked projA cppexe projA_cpplib

executeMake testbuild projB
testLinkedInBuild projB cpplib projA_cpplib test
testLinkedInBuild projB t_cpplib2 cppunit projB_cpplib2 projB_cpplib3

doExit 0
