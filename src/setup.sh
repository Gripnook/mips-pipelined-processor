#!/bin/bash

if [[ -z "$1" ]]; then
	echo "Missing argument";
	exit 1;
fi

cp test-programs/$1/program.txt .

