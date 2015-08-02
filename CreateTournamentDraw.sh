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
[ "$debug" -ne 0 ] && echo "infile=$infile total=$total"

# make a pivot array for applicants.
mapfile -t applicants < "$infile"

# shuffle the applicants
shuffled_applicants=("${applicants[@]}")
[ "$debug" -ne 0 ] && ShowArray "$total" "shuffled_applicants[@]"
for ((loop = 1; loop; loop++))
{
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

# check the number of loop
echo "Shuffle input $loop time(s)"

# get the pivot number for tournament draw
N=1
for ((drawTotal = 1; drawTotal < $total; drawTotal *= 2))
{
  (( N *= 2))
}
(( N /= 2 ))
echo "N=$N total=$total drawTotal=$drawTotal"

# now, create a tournament draw.

# select N applicants from shuffled applicants array
for ((i = 0; i < $drawTotal; ))
{
  x=`expr $RANDOM % $total`
  [ -z "${shuffled_applicants[$x]}" ] && continue
  [ "$debug" -ne 0 ] && echo "i=$i entry=${shuffled_applicants[$x]}"
  draw[ ((i++)) ]="${shuffled_applicants[$x]}"
  draw[ ((i++)) ]=""
  shuffled_applicants[$x]=""
}
[ "$debug" -ne 0 ] && ShowArray "$drawTotal" "draw[@]"

# now, fill the remaining
loop=0
filled=0
for ((i = 0; i < $total; i++))
{
  # already picked?
  [ -z "${shuffled_applicants[$i]}" ] && continue;
  [ "$debug" -ne 0 ] && echo "${shuffled_applicants[$i]}"

  # get an empty draw
  x=0
  for ((j = 1; j; j++))
  {
    x=`expr $RANDOM % $drawTotal`	# the index in draw

    # occupied?
    [ ! -z "${draw[$x]}" ] && continue;
    [ "$debug" -ne 0 ] && echo "x=$x ${draw[$x]}"

    # alternate the sides
    if [ `expr $filled % 2` -eq 0 ]; then
       [ $x -ge $N ] && continue;
    else
       [ $x -lt $N ] && continue;
    fi

    break;
  }
  (( loop += j ))

  # fill it
  draw[$x]="${shuffled_applicants[$i]}"
  shuffled_applicants[$i]=""
  (( filled++ ))
}

# check the number of loop
ShowArray "$drawTotal" "draw[@]"
DumpDraw "Draw.2015.txt" "$drawTotal" "draw[@]"
echo "total=$total filled=$filled"
echo "Complete the draw in $loop time(s)"

exit 0
