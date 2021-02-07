#!/bin/dash
# shrug-branch --- create, check, delete branche

# directories
REPO='.shrug'
OBJ="${REPO}/objects"
BRANCHES="${REPO}/logs/refs/heads"
INDECIES="$REPO/indecies"
MASTER="$BRANCHES/master"
HEADS="$REPO/refs/heads"
# files
HEAD="$REPO/HEAD"
# might be useful
INDEX="${REPO}/index"
HEAD_LOG="${REPO}/logs/HEAD"
REFS="${REPO}/info/refs"

if [ ! -r $MASTER ]; then
    echo "shrug-branch: error: your repository does not have any commits yet" 1>&2
    exit 1
fi

TIP=`cat "$HEAD" | sed -r -e "s@.*: (.*)@$REPO/\1@"`                  # e.g .shrug/refs/heads/master
CURRENT_BRANCH=`echo "$TIP" | sed -r -e "s@.*/.*/(.*)@$BRANCHES/\1@"` # e.g .shrug/logs/refs/heads/master

show_branch() {
    ls $HEADS | cat
}

create_branch() {
    new_branch_name="$1"
    diverging_point=`cat $TIP`
    if [ -f "$HEADS/$new_branch_name" ]; then
        echo "shrug-branch: error: branch '$new_branch_name' already exists" 1>&2
        exit 1
    fi
    # -------- attach index file to the new branch -------- #
    # ------------- index diverges from now on ------------ #
    cp "$INDEX" "$INDECIES/$diverging_point"
    cp $TIP "$HEADS/$new_branch_name" # common tip
    echo "$diverging_point branch Created from `basename $CURRENT_BRANCH`" > "$BRANCHES/$new_branch_name" # create log to the created branch
    echo "$diverging_point branch `basename $CURRENT_BRANCH`:$new_branch_name" >> $HEAD_LOG
}

delete_branch() {
    #---------
    # a branch can only be deleted after it is fully merged into me
    # i.e it's tip is recorded in my commit history
    #---------
    target_name="$1"
    if [ $target_name = "master" ]; then
        echo "shrug-branch: error: can not delete branch 'master'" 1>&2
        exit 1
    elif [ ! -r "$HEADS/$target_name" ]; then
        echo "shrug-branch: error: branch '$target_name' does not exist" 1>&2
        exit 1
    fi

    target_tip=`cat "$HEADS/$target_name"`
    my_tip=`cat $TIP`
    if [ $target_tip != $my_tip ] && ! egrep '^$target_tip ' $CURRENT_BRANCH;
    then # example CURRENT_BRANCH: 1 commit "second commit"
        echo "shrug-branch: error: branch '$target_name' has unmerged changes" 1>&2
        exit 1
    fi
    rm -f "$HEADS/$target_name" "$BRANCHES/$target_name"
    echo "Deleted branch '$target_name'"
}

case "$1" in
    '') # prints out branch names
        show_branch
        ;;
    '-d') # delete the given branch
        shift; delete_branch "$1"
        ;;
    *) # assume legal arguments, create a branch with the given name
        create_branch "$1"
        ;;
esac

