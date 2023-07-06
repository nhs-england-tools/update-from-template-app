#!/bin/sh -l

/compare-directories --dir1=$1 --dir2=$2 --exclude=.git/ > ./output.txt
cat ./output.txt

set -x
files=$(cat ./output.txt | jq -r '.comparison | keys[]')
for file in $files; do
  dir=$(dirname "$file")
  mkdir -p $2/$dir
  cp $1/$file $2/$file
done
