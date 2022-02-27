#!/bin/sh


subdir=$0.d

for hook in $subdir/*
do
	if [ -x $hook ]
	then
		$hook "$@"
		res=$?
		if [ $res != 0 ]
		then
			exit $res
		fi
	fi
done
