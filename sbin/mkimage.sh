#!/bin/sh

mkimage="/usr/local/bin/ubimage"
export RET=0

if [ ! -x "${mkimage}" ]
then
    exit 1
fi

if [ "$#" -lt "2" ]
then
    ${mkimage} --help
    exit 1
fi

${mkimage} $@
