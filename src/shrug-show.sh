#!/bin/dash
# shrug-show --- print out the contents of given file as of the given commit, 
#                if commit is ommited, prints out the content of the file in the index
# Usage: shrug-show [commit]:filename

REPO='.shrug'
INDEX="${REPO}/index"
OBJ="${REPO}/objects"
BASENAME="$(basename $0)"

if [ ! -d "$REPO" ]
then
    echo "$BASENAME: error: no $REPO directory containing shrug repository exists" 1>&2
    exit 1
fi

# ------------------------ parse arguments ------------------------- #
# assume arguments are legal
case "$@" in
    *:*) commit=`echo "$@" | cut -d: -f1 | sed 's/^ *//; s/ *$//'`    #; echo "$commit"
         filename=`echo "$@" | cut -d: -f2-|sed 's/^ *//; s/ *$//'`   #; echo "$filename"
        ;;
    *) echo "usage: $BASENAME <commit>:<filename>"; exit 1
        ;;
esac

# ------------------ retrieve sha1 of given file -------------------- #
if [ "$commit" = "" ]
then  # retrieve sha1 from index
    hash_value=`egrep "^$filename " "$INDEX" | cut -d' ' -f2`
    if [ "$hash_value" = "" ]
    then
        echo "$BASENAME: error: '$filename' not found in index" 1>&2
        exit 1
    fi
elif [ ! -f "${OBJ}/$commit" ]
then
    echo "$BASENAME: error: unknown commit '$commit'"
    exit 1
else  # retrieve sha1 from given commit
    hash_value=`egrep "^$filename " "${OBJ}/$commit" | cut -d' ' -f2`
    if [ "$hash_value" = "" ]
    then
        echo "$BASENAME: error: '$filename' not found in commit $commit" 1>&2
        exit 1
    fi
fi

# ----------------------- print out content ------------------------- #
cat "${OBJ}/$hash_value"
