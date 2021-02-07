#!/bin/sh
# compares the differences between pre and post branch

echo "###### /HEAD ######" >> pre_switch
cat .shrug/.git/HEAD >> pre_switch
echo >> pre_switch

echo "###### /index ######" >> pre_switch
cat .shrug/.git/index >> pre_switch
echo >> pre_switch

echo "###### /info/refs ######" >> pre_switch
cat .shrug/.git/info/refs >> pre_switch
echo >> pre_switch

echo "###### /logs/HEAD ######" >> pre_switch
cat .shrug/.git/logs/HEAD >> pre_switch
echo >> pre_switch

echo "###### /logs/refs/heads/b1 ######" >> pre_switch
cat .shrug/.git/logs/refs/heads/b1 >> pre_switch
echo >> pre_switch


echo "###### /logs/refs/heads/master ######" >> pre_switch
cat .shrug/.git/logs/refs/heads/master >> pre_switch
echo >> pre_switch

echo "###### /refs/heads/b1 ######" >> pre_switch
cat .shrug/.git/refs/heads/b1 >> pre_switch
echo >> pre_switch
