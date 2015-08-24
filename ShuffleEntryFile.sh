#!/bin/bash

# initialize variables
debug=0
loop=7
magic=1000000
entryfile=""
OUTPUT="shffled_entry.txt"

USAGE="Usage: $0 [-loop=7] entry-file"

# parse the arguments
while (( "$#" )); do

  # option argument
  if [ ${1:0:1} = '-' ]; then
    tmp=${1:1}              # strip off leading '-'
    parameter=${tmp%%=*}    # extract name
    value=${tmp##*=}        # extract value
    eval $parameter=$value
  else
    if [ "$entryfile" == "" ]; then
      entryfile="$1"
    else
      echo "'$1': Too many files"
      exit 1
    fi
  fi

  shift

done

# check the arguments
[ -z "$entryfile" ] && echo "$USAGE" && exit 1

# run loop times
[ -e "tmpfile" ] && $(rm "tmpfile")
$(cp "$entryfile" "$OUTPUT")	# copy entry file

for ((i = 1; i <= $loop; i++))
{
  # show progress
  printf "Shuffle the entry file %d times\r" "$i"

  if [ -e "tmpfile" ]; then
    result=$(diff "$OUTPUT" "tmpfile")	# prepare the next run
    [ $? -eq 0 ] && echo "Same?" && exit 2
  fi

  $(mv "$OUTPUT" "tmpfile")	# prepare the next run

  cat "tmpfile" | awk 'BEGIN \
    { srand() } \
    { printf "%06d %s\n", rand()*1000000, $0; }' | sort -n | cut -c8- > "$OUTPUT"
}

echo

# show the result line by line
nth=1
cat "$OUTPUT" | while read new_entry; do
  i=1
  cat "$entryfile" | while read old_entry; do
    [ `expr $i - $nth` -eq 0 ] && printf "%2d: %s >= %s\n" "$nth" "$old_entry" "$new_entry" && break
    (( i++ ))
  done
  (( nth++ ))
  #printf "%2d: %s => %s\n" "$nth" "$old_entry" "$new_entry"
done

$(rm "tmpfile")

exit 0
