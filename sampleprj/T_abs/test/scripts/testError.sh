#!/bin/bash

source $(dirname $0)/initTest.sh testError

NOBUILD=cpplib executeMakeWithError all projA 

testBuildLogContains projA "cppexe: Can't build because of deactivated dependency: cpplib"

doExit 0
