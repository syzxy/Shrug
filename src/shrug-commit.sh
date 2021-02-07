#!/bin/dash
# shrug-commit --- saves a copy of all files in the index to the repository.
# shrug-commit [-a] -m message
# commands:
# -m msg: a message describing the commit
# message: assumed to be legal, i.e. ASCII and not starting with '-'
# -a : optional, causes all files in the index to have their contents from the current directory
#      added to the index before commit

# directories
REPO='.shrug'
OBJ="${REPO}/objects"
HEADS="${REPO}/logs/refs/heads"
INDECIES="${REPO}/indecies" # backups of index files per branch tip
# files
HEAD="$REPO/HEAD"
INDEX="${REPO}/index"
TIP=`cat "$HEAD" | sed -r -e "s@.*: (.*)@$REPO/\1@"`
#BRANCH="${HEADS}/master"
BRANCH=`echo "$TIP" | sed -r -e "s@.*/.*/(.*)@$HEADS/\1@"`
HEAD_LOG="${REPO}/logs/HEAD"
REFS="${REPO}/info/refs"

abort() {
    echo "usage: shrug-commit [-a] -m commit-message" 1>&2
    exit 1
}

# ---------- check if argument to -m is legal ----------- #
check_msg() {
    if [ "$message" = "" ]; then abort; fi
    if echo "$message" | egrep -- '^\-.*' >/dev/null; then abort; fi
}

# ---------- update index file if -a provided ----------- #
update_index() {
    if [ -r "$INDEX" ]
    then
        cat "$INDEX" | cut -d' ' -f1 | xargs shrug-add        
    fi
}

# ------------------- parse options --------------------- #
if ! [ -d $REPO ]; then      # repo does not exist
    echo "$(basename $0): error: no $REPO directory containing shrug repository exists" 1>&2
    exit 1
elif [ $# -lt 2 -o $# -gt 3 ]; then abort 
fi
while true
do
#    echo "now arguments are $@ and \$1 is $1"
    case $1 in
        -m) message="$2"; check_msg; shift 2 
            [ $1 ] || break # breake when all arguments have been parsed
#            echo "$1 is last"
            ;;
        -a) update_index; shift 1; [ $1 ] || break
#            echo "-a is first, because $1 = $2"
            ;;
        *) abort ;;
    esac
done

# ---------------- commit files in index ----------------- #

# 1. check if there are anything to commit
if ! [ -r $INDEX ]  # index file does not exitst
then
    echo "nothing to commit"
    exit 0
elif ! egrep '^.* (initial|staged|deleted) .*$' "$INDEX" > /dev/null   # no staged or deleted files in index
then
    echo "nothing to commit"
    exit 0
fi

# 2. create commit object
if ! [ -f "$HEAD" ]
then
    echo 'ref: refs/heads/master' > "$HEAD"
elif ! [ -f "$BRANCH" ] 
then
    mkdir -p "$HEADS"
    serial=0
else
    serial=`tail -1 "$HEAD_LOG" | cut -d' ' -f1`
    serial=$(( serial + 1 ))
fi
egrep -v '^.* deleted .*$' "$INDEX" |    # files except deleted ones in index
cut -d' ' -f1,2 >> "${OBJ}/${serial}"    # record these files and their sha1 in a commit file

# 3. change status of commited files in index; remove deleted files from index
sed -r -i "s/^(.* )(staged|initial) .*$/\1same $serial/g; s/.* deleted .*//g" "$INDEX"

# 4. LOG
echo "$serial" > "$TIP"
echo "$serial commit $message" >> "$BRANCH"
echo "$serial commit $message" >> "$HEAD_LOG"
mkdir -p "$INDECIES"
cp "$INDEX" "$INDECIES/$serial"
echo "Committed as commit $serial"
