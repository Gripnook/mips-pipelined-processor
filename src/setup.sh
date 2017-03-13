#!/bin/bash

# Sets up the test program for simulation

print_usage () {
	echo "Usage: ./setup.sh <program>";
	return;
}

if [[ -z "$1" ]]; then
	print_usage;
	exit 1;
fi

cp test-programs/$1/program.txt .

