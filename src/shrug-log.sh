#!/bin/dash
# shrug-log --- prints out all commits line by line
# fomat: commit-number message

#files
REPO='.shrug'
# TODO retrieve brach path from, say, .shrg/HEAD
HEAD="$REPO/HEAD"
HEAD_LOG="$REPO/logs/HEAD"
BRANCHES="${REPO}/logs/refs/heads"
TIP=`cat "$HEAD" | sed -r -e "s@.*: (.*)@$REPO/\1@"`                  # e.g .shrug/refs/heads/master
CURRENT_BRANCH=`echo "$TIP" | sed -r -e "s@.*/.*/(.*)@$BRANCHES/\1@"` # e.g .shrug/logs/refs/heads/master
BASENAME="$(basename $0)"

if [ ! -d "$REPO" ]
then
    echo "$BASENAME: error: no $REPO directory containing shrug repository exists" 1>&2
    exit 1
elif [ ! -d $BRANCHES ]
then
    echo "$BASENAME: error: your repository does not have any commits yet" 1>&2
    exit 1
fi

print_branch_log() {
    branch_log="$BRANCHES/$1"
    diverging_piont=`head -1 "$branch_log" | cut -d' ' -f1`
    keyword=`head -1 "$branch_log" | cut -d' ' -f2`
    num_records=`cat "$branch_log" | wc -l `
    tail -`expr "$num_records" - 1` "$branch_log" | cut -d' ' -f1,3- | sort -n -r
    
    if [ $diverging_piont -eq 0 ] && [ $keyword != 'branch' ]; then
        head -1 $branch_log | cut -d' ' -f1,3-
    else
        head -`expr $diverging_piont + 1` "$HEAD_LOG" | cut -d' ' -f1,3 | sort -n -r
    fi
}
branch_name=`basename $TIP`
print_branch_log "$branch_name"

#cat "$BRANCH" |
#cut -d' ' -f1,3- |  # commit number and commit message
#sort -n -r          # latest commit on top
