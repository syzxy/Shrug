#!/bin/dash
# shrug-init --- create .shrug directory in current directory if it does not already exits

# directories
REPO='.shrug'
OBJ="${REPO}/objects"
BRANCHES="${REPO}/branches"
INFO="${REPO}/info"
HEADS="${REPO}/refs/heads"
TAGS="${REPO}/refs/tags"
# files
HEAD="${REPO}/HEAD"

if [ -d $REPO ]
then
    echo "$(basename $0): error: $REPO already exists" 1>&2
    exit 1
fi

for dir in $OBJ $BRANCHES $INFO $HEADS $TAGS
do
    mkdir -p "$dir"
done
echo "ref: refs/heads/master" >> "$HEAD"
echo "Initialized empty shrug repository in .shrug"
