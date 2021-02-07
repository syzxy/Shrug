#!/bin/dashs
# shrug-checkout --- checkout a given branch

# directories
REPO='.shrug'
OBJ="${REPO}/objects"
INDECIES="${REPO}/indecies" # back up index before checkout, reset after checkout
#BRANCHES="${REPO}/logs/refs/heads"
HEADS="$REPO/refs/heads"
HEAD_LOG="$REPO/logs/HEAD"


# files
INDEX="${REPO}/index"
HEAD="$REPO/HEAD"
TIP=`cat "$HEAD" | sed -r -e "s@.*: (.*)@$REPO/\1@"`                  # e.g .shrug/refs/heads/master
#CURRENT_BRANCH=`echo "$TIP" | sed -r -e "s@.*/.*/(.*)@$BRANCHES/\1@"` # e.g .shrug/logs/refs/heads/master
# might be useful
#REFS="${REPO}/info/refs"

target_name="$1"
if [ ! -r "$HEADS/$target_name" ]; then
    echo "shrug-checkout: error: unknown branch '$target_name'" 1>&2
    exit 1
elif [ "$target_name" = `basename $TIP` ]; then
    echo "Already on '$target_name'";
    exit 0
fi

# backup current index before switch 
# TODO -- done also in commit, repeated work?
current_tip=`cat $TIP`
if [ ! -d $INDECIES ]; then
    mkdir -p $INDECIES
fi
cat "$INDEX" > "$INDECIES/$current_tip"

new_tip=`cat "$HEADS/$target_name"`

# reset index
if [ -r "$INDECIES/$new_tip" ]; then
    cp "$INDECIES/$new_tip" "$INDEX"
fi

for file in `ls -a`; do
    if [ -f $file ] \
        && egrep "^$file " "$INDECIES/$current_tip" >/dev/null \
        && ! egrep "^$file " "$INDEX" >/dev/null
    then
        rm -f "$file"
    fi
done

# revert snapshot --- don't touch files that has uncommitted changes since the diverging point
snapshot="$OBJ/$new_tip"
while read -r line; do
    filename=`echo $line | sed -r -e 's/^(.*) .*$/\1/'`
    target_blob=`echo $line | sed -r -e 's/^.* (.*)$/\1/'`
    if [ ! -f $filename ]; then
        cp "$OBJ/$target_blob" "$filename"
    else
        hash_value=`sha1sum $filename|cut -d' ' -f1`
        current_blob=`egrep "^$filename " "$OBJ/$current_tip"| cut -d' ' -f2`
        if [ -z $current_blob ]; then
            echo "shrug-checkout: error: Your changes to the following files would be overwritten by checkout:\n$filename" 1>&2
            exit 1
        elif [ $hash_value != $target_blob ] && [ $hash_value = $current_blob ]; then
            cp "$OBJ/$target_blob" "$filename"
            sed -i -r "s/^($filename) .* .* .*$/\1 $target_blob same $new_tip/" "$INDEX"
        fi
    fi
done < "$snapshot"

# point HEAD to target
echo "ref: refs/heads/$target_name" > "$HEAD"
echo "Switched to branch '$target_name'"

