#!/bin/dash
# shrug-rm --- remove file from index or both index and cwd
# Usage: shrug-rm [--force] [--cached] files
# options are given only in the above order, i.e --cached can not appear before --forced in not omitted
# shrug-rm can not remove a file only from cwd. When no options are given, it tries to remove files from
# both cwd and index, this is possible only when the file is identical to the tip of the branch, and no
# changes are staged in index, i.e. shrug-status file gives "same as repo"
# When --cached is given, tries to remove file from index directly. This is possible when the staged content
# in index is identical to the file on disc or to the tip of the branch. i.e. shrug-status file gives "same as repo", "changes not staged" or "changes staged". ("different changes staged" will cause error)


REPO='.shrug'
BRANCH="$REPO/logs/refs/heads/master"
INDEX="$REPO/index"
BASENAME="`basename $0`"

# ----------------- retrieve file state in index --------------- #
read_state_from_index() {
    cat "$INDEX" | egrep "^$1 " | cut -d' ' -f3
}

# ------------ exit if any file given is not in index ----------- #
check_existence(){
    for file in "$@"
    do
        state=`read_state_from_index "$file"`
#        echo "file: $file, state: $state"
        if [ "$state" = '' -o "$state" = 'deleted' ]; then
            echo "$BASENAME: error: '$file' is not in the shrug repository" 1>&2
            exit 1
        fi
    done
}

rm_from_index() {
#    echo"rm from index"
    check_existence "$@"
    for file in "$@"; do
        state=`read_state_from_index "$file"`
        case "$state" in
            same) 
#                sed -i -r "s/^$file .* .* .*$//" "$INDEX"
                sed -i -r "s/^($file .* ).*( .*)$/\1deleted\2/" "$INDEX"
                ;;
            staged|initial) 
                hash_value=`sha1sum "$file" | cut -d' ' -f1`
                previous_hash=`egrep "^$file " "$INDEX" | sed -r "s/^.* (.*) .* .*$/\1/"`
                case $hash_value in
                    $previous_hash)
                        if [ "$state" = staged ]; then
#                            sed -i -r "s/^$file .* .* .*$//" "$INDEX"
                            sed -i -r "s/^($file .* ).*( .*)$/\1deleted\2/" "$INDEX"
                        else
                            sed -i -r "s/^$file .* .* .*$//" "$INDEX"
                        fi
                        ;;
                    *) echo "$BASENAME: error: '$file' in index is different to both working file and repository" 1>&2 ;exit 1
                        ;;
                esac
                ;;
#            initial)
#                hash_value=`sha1sum "$file" | cut -d' ' -f1`
#                previous_hash=`sed -r "s/^$file (.*) .* .*$/\1/" "$INDEX"`
#                case $hash_value in
#                    $previous_hash) 
#                        ;;
#                    *) echo "$BASENAME: error: '$file' in index is different to both working file and repository" 1>&2 
#                       exit 1
#                        ;;
#                esac
#                ;;
        esac
    done
}

rm_from_index_and_cwd() {
    check_existence "$@"
    for file in "$@"; do
        state=`read_state_from_index "$file"`
        hash_value=`sha1sum "$file" | cut -d' ' -f1`
        previous_hash=`egrep "^$file " "$INDEX" | sed -r "s/^.* (.*) .* .*$/\1/"`
        if [ "$state" != 'same' -a "$hash_value" != "$previous_hash" ]; then
            echo "$BASENAME: error: '$file' in index is different to both working file and repository" 1>&2
            exit 1
        elif [ "$state" != 'same' ]; then
            echo "$BASENAME: error: '$file' has changes staged in the index" 1>&2
            exit 1
        elif [ "$hash_value" != "$previous_hash" ]; then
            echo "$BASENAME: error: '$file' in repository is different to working file" 1>&2
            exit 1
        elif [ "$state" = 'same' -a "$hash_value" = "$previous_hash" ]; then
            sed -i -r "s/^($file .* ).*( .*)$/\1deleted\2/" "$INDEX"
            rm -f "$file"
        fi
    done
}

# --------------------- force option provided ------------------- #
# --force will remove the file from index anyway 
# rather than change it's state to deleted when the state is not initial in non-force mode
force_rm() {
#    echo "force remove"
    case "$1" in
        --cached) cached=0; shift 1
            ;;
        *) cached=1
            ;;
    esac
    check_existence "$@"
    for file in "$@"; do
        sed -i -r "s/^$file .* .* .*$//g" "$INDEX" 
        if [ $cached -eq 1 ]; then
            rm -f "$file" >/dev/null
        fi
    done
}


if [ ! -d "$REPO" ]; then
    echo "$BASENAME: error: no $REPO directory containing shrug repository exists" 1>&2
    exit 1
elif [ ! -r "$BRANCH" ]; then
    echo "$BASENAME: error: your repository does not have any commits yet" 1>&2
    exit 1
fi

case "$1" in
    '') echo "usage: $BASENAME [--force] [--cached] <filenames>" 1>&2; exit 1
        ;;
    --force) shift 1; force_rm "$@"
        ;;
    --cached) shift 1; rm_from_index "$@"
        ;;
    *) rm_from_index_and_cwd "$@" #assume filenames are legal
        ;;
esac
