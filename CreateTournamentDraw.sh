#!/bin/bash

# create a tournament draw from the given applicants file.

OPTION="[-debug=0]"
USAGE="Usage: $0 applicants-list-file"

# check the number of argument
# [ $# -ne 1 ] && echo "$USAGE" && exit 1

# initialize variables
N=0
debug=0
infile=""

# include functions
source "./IncludeFunctions.sh"

# main function
while (( "$#" )); do

  # option argument
  if [ ${1:0:1} = '-' ]; then
    tmp=${1:1}			# strip off leading '-'
    parameter=${tmp%%=*}	# extract name
    value=${tmp##*=}		# extract value
    eval $parameter=$value

  elif [ -e "$1" ]; then
    if [ -z "$infile" ]; then
      infile="$1"		# it's an applicants list file
    else
      echo "$USAGE"
      break;
    fi
  else
    break;
  fi

  shift

done

# check applicant file and number
[ -z "$infile" ] && echo "No Applicants list file" && exit 1

# total number of applicants
total=$(wc "$infile" | awk '{ print $1 }')

# Do the task
echo "'$infile': $total entries"

# make a pivot array for applicants.
mapfile -t applicants < "$infile"

# shuffle the applicants
shuffled_applicants=("${applicants[@]}")
for ((loop = 1; loop; loop++))
{
  # show progress
  printf "Shuffle the entries %d times\r" "$loop"

  # swap contents
  x=`expr $RANDOM % $total`
  y=`expr $RANDOM % $total`

  # same number?
  [ "$x" -eq "$y" ] && continue

  tmp="${shuffled_applicants[$x]}"
  shuffled_applicants[$x]="${shuffled_applicants[$y]}"
  shuffled_applicants[$y]="$tmp"

  # compare two arrays
  CompareArrays "$total" "applicants[@]" "shuffled_applicants[@]"
  [ "$?" -eq 0 ] && break;
}
printf "Shuffle the entries %d times\n" "$loop"
[ "$debug" -ne 0 ] && ShowArrays "$total" "applicants[@]" "shuffled_applicants[@]"

# get the pivot number for tournament draw
N=1
for ((drawTotal = 1; drawTotal < $total; drawTotal *= 2))
{
  (( N *= 2))
}
(( N /= 2 ))
echo "Total entries=$total Draw Total=$drawTotal"

# now, create a tournament draw.

# select N applicants from shuffled applicants array
j=0
for ((i = 0, loop = 1; i < $drawTotal; loop++))
{
  # show progress
  printf "Select %d entries in %d times\r" "$j" "$loop"

  x=`expr $RANDOM % $total`
  [ -z "${shuffled_applicants[$x]}" ] && continue

  (( j++ ))
  draw[ ((i++)) ]="${shuffled_applicants[$x]}"
  draw[ ((i++)) ]=""
  shuffled_applicants[$x]=""
}
printf "Select %d entries in %d times\n" "$j" "$loop"
[ "$debug" -ne 0 ] && ShowArray "$drawTotal" "draw[@]"

# now, fill the remaining
loop=0
filled=0
for ((i = 0; i < $total; i++))
{
  # show progress
  printf "Fill %d entries in %d times\r" "$filled" "$loop"

  # already picked?
  [ -z "${shuffled_applicants[$i]}" ] && continue;

  # get an empty draw
  x=0
  for ((j = 1; j; j++))
  {
    x=`expr $RANDOM % $drawTotal`	# the index in draw

    # show progress
    (( loop++ ))
    printf "Fill %d entries in %d times\r" "$filled" "$loop"

    # occupied?
    [ ! -z "${draw[$x]}" ] && continue;

    # alternate the sides
    if [ `expr $filled % 2` -eq 0 ]; then
       [ $x -ge $N ] && continue;
    else
       [ $x -lt $N ] && continue;
    fi

    break;
  }

  # fill it
  draw[$x]="${shuffled_applicants[$i]}"
  shuffled_applicants[$i]=""
  (( filled++ ))
}

# check the number of loop
printf "Fill %d entries in %d times\n" "$filled" "$loop"
ShowArray "$drawTotal" "draw[@]"
DumpDraw "Draw.2015.txt" "$drawTotal" "draw[@]"

exit 0
