#!/usr/bin/env bash

echo -e "\nStatus\n"
git status

count="$1"
shift

if [ -z  "$count" ] ; then
    count=10
fi

echo -e "\nCommits\n"
git log --pretty=oneline --pretty=format:"%H %ae %aD %s" | head -$count
echo -e "\nTags\n"

for c in `git tag --list | sort --version-sort -r | head -$count `; do
    commit=`git rev-list -n 1 $c | cut -c1-7`
    echo "$c: `git log --pretty=oneline --pretty=format:"%h %ae %aD %s" | grep $commit`"
done

echo -e "\nBranches\n"
git branch -a -vvv | grep -v "remotes"
