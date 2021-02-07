#!/bin/dash
# shrug-add --- adds given files to the "index"
# index     --- here is implemented as a subdirectory of .shrug
# files accepted --- ordinary files
# file names     --- starts with [a-zA-Z0-9] and contains only [a-zA-Z0-9.-_]

REPO='.shrug'
OBJ="${REPO}/objects"
INDEX="${REPO}/index"
BASENAME="$(basename $0)"

if [ "$#" -eq 0 ]
then
    echo "usage: $BASENAME <filenames>" 1>&2
    exit 1
elif ! [ -d "$REPO" ]
then
    echo "$BASENAME: error: no $REPO directory containing shrug repository exists" 1>&2
    exit 1
fi
[ -f "$INDEX" ] || touch "$INDEX"

for file in "$@"
do
    echo "$file" | egrep '^[a-zA-Z0-9][-a-zA-Z0-9\._]*$' >/dev/null
    if [ $? -ne 0 ]
    then
        echo "$BASENAME: error: invalid filename '$file'"
    elif [ ! -r "$file" ] && ! egrep "^$file " "$INDEX" >/dev/null
    then
        echo "$BASENAME: error: can not open '$file'" 1>&2
        exit 1
    elif [ ! -r "$file" ]
    then
        sed -i -r "s/^($file .*) .* (.*)$/\1 deleted \2/" "$INDEX"
    else
        # --------- add <filename sha1 status> to index --------- #
        hash_value=`sha1sum "$file" | cut -d' ' -f1`
        if [ ! -f "${OBJ}/${hash_value}" ]
        then
            cp "$file" "${OBJ}/${hash_value}"
        fi
        state=`egrep "^$file " "$INDEX" | sed -r -e "s/^$file .* (.*) .*$/\1/"`

        # commit number, -1 if never commited, '' if file not in index
        commit=`egrep "^$file " "$INDEX" | cut -d' ' -f4` 
        case "$commit" in
            '') # file not found in index
                echo "$file $hash_value initial -1" >> "$INDEX"
                ;;
            -1) # file was added but never committed before e.g. "file1 sha1sum initial -1"
                sed -i -r "s/^($file) .* (.* .*)$/\1 $hash_value \2/" "$INDEX"
                ;;
            *)  # file had been commited before
                previous_hash=`egrep "^$file " "$INDEX" | cut -d' ' -f2`
                if [ $hash_value = $previous_hash -a $state != 'staged' ]; then
                    sed -i -r "s/^($file) .* .* (.*)$/\1 $hash_value same \2/" "$INDEX"
                else
                    sed -i -r "s/^($file) .* .* (.*)$/\1 $hash_value staged \2/" "$INDEX"
                fi
                ;;
        esac
    fi
done

