#!/bin/dash

#shrug-init
#echo hello >a
#shrug-add a
#shrug-commit -m commit-A
#shrug-branch branchA
#echo world >b
#shrug-add b
#shrug-commit -m commit-B
#shrug-checkout branchA
#echo new contents >b
#shrug-checkout master

a=4
tail -`expr $a - 1` "$1"
