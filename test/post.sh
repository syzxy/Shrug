#!/bin/sh
# compares the differences between pre and post branch

echo "###### /HEAD ######" >> post_switch
cat .shrug/.git/HEAD >> post_switch
echo >> post_switch

echo "###### /index ######" >> post_switch
cat .shrug/.git/index >> post_switch
echo >> post_switch

echo "###### /info/refs ######" >> post_switch
cat .shrug/.git/info/refs >> post_switch
echo >> post_switch

echo "###### /logs/HEAD ######" >> post_switch
cat .shrug/.git/logs/HEAD >> post_switch
echo >> post_switch

echo "###### /logs/refs/heads/b1 ######" >> post_switch
cat .shrug/.git/logs/refs/heads/b1 >> post_switch
echo >> post_switch


echo "###### /logs/refs/heads/master ######" >> post_switch
cat .shrug/.git/logs/refs/heads/master >> post_switch
echo >> post_switch

echo "###### /refs/heads/b1 ######" >> post_switch
cat .shrug/.git/refs/heads/b1 >> post_switch
echo >> post_switch
