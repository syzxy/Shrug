#!/bin/dash
# shrug-merge --- merge a branch or a commit
# directories
REPO='.shrug'
OBJ="${REPO}/objects"
BRANCHES="${REPO}/logs/refs/heads"
INDECIES="$REPO/indecies"
HEADS="$REPO/refs/heads"
# files
HEAD="$REPO/HEAD"
# might be useful
INDEX="${REPO}/index"
HEAD_LOG="${REPO}/logs/HEAD"

if [ ! -d "$REPO" ]
then
    echo "shrug-merge: error: no $REPO directory containing shrug repository exists" 1>&2
    exit 1
elif [ ! -r "$HEAD_LOG" ]
then
    echo "shrug-merge: error: your repository does not have any commits yet" 1>&2
    exit 1
elif [ $# -eq 1 ]
then
    echo "shrug-merge: error: empty commit message" 1>&2
    exit
elif [ ! $# -eq 3 ] || [ ! $2 = '-m' ]
then
    echo "usage shrug-merge <branch|commit> -m message" 1>&2
    exit 1
fi

merge_file() {
    from="$1"
    to="$2"
    diverging_point=`find_diverge_point "$from" "$to"`
    ancestor="$OBJ/$diverging_point"
    cf=`cat "$from" | wc -l`
    ct=`cat "$to" | wc -l`
    ca=`cat "$ancestor" | wc -l`
    if [ cf -ne ca -o ct -ne ca ]; then
        return 1
    fi
    
}

find_diverge_point() {
    if egrep "branch:.*$1" "$BRANCHES/$2" >/dev/null; then
        diverging_point=`egrep "branch:.*$1" "$BRANCHES/$2" | cut -d' ' -f1`
        echo "$diverging_point"
    else
        diverging_point=`egrep "branch:.*$2" "$BRANCHES/$1" | cut -d' ' -f1`
    fi
}

merge_commit() {
    target="$1"
    current_branch=`cat $HEAD | cut -d'/' -f3`
    current_tip=`cat "$HEADS/$current_branch"`
    if egrep "^$target " "$BRANCHES/$current_branch" >/dev/null; then
        echo "Already up to date"
        exit 0;
    elif egrep "^$current_tip " "$BRANCHES/$current_branch" >/dev/null; then
        fast_forward 
    fi
    while read -r line; do
        filename=`echo $line | cut -d' ' -f1`
        target_blob=`echo $line | cut -d' ' -f2`
        #state=`echo $line | cut -d' ' -f3`
        #commit=`echo $line | cut -d' ' -f4`
        if ! egrep "^$filename " "$OBJ/$current_tip" /dev/null; then
            cp "$OBJ/$target_blob" "$filename"
            shrug-add $filename
        else
            blob=`egrep "^$filename " "$BRANCHES/$current_branch" | cut -d' ' -f2`
            merge_file "$OBJ/$target_blob" "$OBJ/$blob" 
            if [ $? -ne 0 ]; then
                echo "shrug-merge: error: These files can not be merged:\n$filename" 1>&2
                exit 1
            fi
            echo "Auto-merging $filename"
            cp "$OBJ/$blob" "$filename"
            shrug-add $filename
        fi
    done < "$OBJ/$target"
}

fast_forward() {
    echo "Fast-forward: no commit created"
    exit 0
}

merge_branch() {
    target_tip=`cat "$HEADS/$1"`
    merge_commit $target_tip
}

message="$3"
if echo "$1" | egrep '^[0-9]+$' > /dev/null; then
    # merge commit
    commit="$1"
    merge_commit $commit
else
    #merge branch
    branch_name="$1"
    merge_branch $branch_name
fi
shrug-commit -a -m "$message"
