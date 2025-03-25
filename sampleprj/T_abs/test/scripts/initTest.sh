#!/bin/bash

testName=$1

if [ ! -d $TTARGETDIR ]; then
    echo "No TTARGETDIR variable defined"
    exit 1
fi

if [ "$MODE" = "" ]; then
MODE=debug
fi

testDirectory=$TTARGETDIR/$testName
MODROOT=`pwd`
PRJROOT=$MODROOT/../../
chmod -R +w $testDirectory
rm -rf $testDirectory
mkdir -p $testDirectory
mkdir -p $testDirectory/absws
mkdir -p $testDirectory/repository/NotALinux
mkdir -p $testDirectory/repository/noarch
echo "Copy resources to $testDirectory"

ln -s $PRJROOT $testDirectory/absws/abs-99.99.99
cp -R test/resources/proj* test/resources/libtest test/resources/libtest2 test/resources/testlib-dashed test/resources/cppunit test/resources/tracy $testDirectory

unset TTARGETDIR
unset TRDIR

function doExit {
    # The symlink over PRJROOT strangely makes pdflatex hangs when heml doc is generated
    # after this test, then remove the directory to make it run.
    rm $testDirectory/absws/abs-99.99.99
    exit $1
}

function testFileExists {
    if [ ! -f $1 ]; then
        echo "Error: File $1 doesn't exists"
        doExit 13
    fi
}

function testFile {
    diff -q $1 $2
    if [ $? -ne 0 ]; then
        echo "Error: $1 not equal to $2"
        doExit 6
    fi
}

function executeMake {
    module=$2
    goal=$1
    echo ""
    echo "### Execution $module on $goal"
    echo ""
    shift;shift;
    # reset makelevel to 0
    MAKELEVEL=0 ARCH=NotALinux make -C $module $goal ABS_LOG_LEVEL=debug $*
    if [ $? -ne 0 ]; then
        echo "Error while executing make $goal on $module"
        doExit 11
    fi
}

# 1: project
# 2: module
# *: links
function testLinked {
    project=$1
    module=$2
    shift;shift;
    expected=" $module linked to $*"
    buildlog=`find $testDirectory/$project/dist/flatten/*/obj/build.log`
    testFileExists $buildlog
    grep -E -q "$expected\$" $buildlog
    if [ $? -ne 0 ]; then
        echo "Logs analyzed: $buildlog"
        echo "Error, cannot find $expected"
        doExit 12
    fi
}

# 1: project
# 2: module
# *: links
function testLinkedInBuild {
    project=$1
    module=$2
    shift;shift;
    expected=" $module linked to $*"
    buildlog=`find $testDirectory/$project/build/NotALinux/*/obj/build.log`
    testFileExists $buildlog
    grep -E -q "$expected\$" $buildlog
    if [ $? -ne 0 ]; then
        echo "Logs analyzed: $buildlog"
        echo "Error, cannot find $expected"
        doExit 12
    fi
}

# 1: project
# 2: version non imported
# 3: version imported
function testNotImported {
    project=$1
    notImported=$2
    imported=$3
    expected="$notImported not imported because different version: $imported"
    buildlog=`find $testDirectory/$project/dist/flatten/*/obj/build.log`
    testFileExists $buildlog
    grep -q "$expected" $buildlog
    if [ $? -ne 0 ]; then
        echo "Logs analyzed: $buildlog"
        echo "Error, cannot find $expected"
        doExit 13
    fi
}

cd $testDirectory
executeMake pubdist cppunit
executeMake pubdist tracy

executeMake pubdist libtest2
executeMake pubdist libtest
executeMake pubdist testlib-dashed