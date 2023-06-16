#!/bin/sh

if [ $# = 2 ]; then exit 0; fi

SED=`which gsed sed 2>/dev/null | grep -v not.found | head -1`

jq '.[1]' | $SED "s/\[\]{ *#\([^}]\+\) *}/<a id='\1'><\/a>/g"
