#!/bin/bash

if [[ -z "$1" ]]; then
	echo "Missing argument";
	exit 1;
fi

diff -ws memory.txt test-programs/$1/memory.txt
diff -ws register_file.txt test-programs/$1/register_file.txt

