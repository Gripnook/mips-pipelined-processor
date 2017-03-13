#!/bin/bash

# Compares the simulation results to the expected results

print_usage () {
	echo "Usage: ./compare.sh <program>";
	return;
}

if [[ -z "$1" ]]; then
	print_usage;
	exit 1;
fi

diff -ws memory.txt test-programs/$1/memory.txt
diff -ws register_file.txt test-programs/$1/register_file.txt

