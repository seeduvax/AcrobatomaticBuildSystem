#!/bin/bash

source $(dirname $0)/initTest.sh testError

executeMakeWithError all projA NOBUILD=cpplib

testBuildLogContains projA "cppexe: Can't build because of deactivated dependency: cpplib"

doExit 0
