#!/bin/dash
# shrug-status --- shows the status of files in cwd, the index, and the repository

REPO='.shrug'
INDEX="$REPO/index"
BRANCH="$REPO/logs/refs/heads/master"
BASENAME="$(basename $0)"

if [ ! -d "$REPO" ]
then
    echo "$BASENAME: error: no $REPO directory containing shrug repository exists" 1>&2
    exit 1
elif [ ! -r "$BRANCH" ]
then
    echo "$BASENAME: error: your repository does not have any commits yet" 1>&2
    exit 1
fi

status_of_cwd() {
    for file in `ls`
    do
        [ -d "$file" ] && continue
        #    if ! egrep "^$file " "$INDEX" >/dev/null
        #    then
        #        echo "$file - untracked"
        #    else
        hash_value=`sha1sum "$file" | cut -d' ' -f1`
        previous_hash=`egrep "^$file " "$INDEX" | cut -d' ' -f2`
        index_state=`egrep "^$file " "$INDEX" | cut -d' ' -f3`
        case "$index_state" in
            deleted) status="untracked"
                ;;
            initial)
                case $hash_value in
                    $previous_hash) status="added to index" ;;
                    *) status="added to index, file changed" ;;
                esac
                ;;
            staged)
                case $hash_value in
                    $previous_hash) status="file changed, changes staged for commit" ;;
                    *) status="file changed, different changes staged for commit" ;;
                esac
                ;;
            same)
                case $hash_value in
                    $previous_hash) status="same as repo" ;;
                    *) status="file changed, changes not staged for commit" ;; 
                esac
                ;;
            *) status="untracked"
        esac
        echo "$file - $status"
        #    fi
    done
}

status_of_index() {
    for file in `cat "$INDEX" | cut -d' ' -f1`; do
        if [ ! -r "$file" ] ; then
            state=`egrep "^$file " "$INDEX" | cut -d' ' -f3`
            case "$state" in
                deleted) status="deleted" ;;
                initial) status="added to index, file deleted" ;;
                *) status="file deleted" ;;
            esac
            echo "$file - $status"
        fi
    done
}

{ status_of_cwd; status_of_index; } | sort -n
