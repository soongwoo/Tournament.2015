#!/bin/bash

# Select N applicants from the given applicants file.
# (Assume that there are two selection groups such as Group A and Group B.)

OPTION="[-debug=0]"
USAGE="Usage: $0 N applicants-list-file"

# check the number of argument
# [ $# -ne 2 ] && echo "$USAGE" && exit 1

# initialize variables
N=0
debug=0
infile=""

# function list array
function ShowArray
{
  argArray=("${!2}")
  for ((i = 0; i < "$1"; i++)); do
    echo "$i: ${argArray[$i]}"
  done
}

# compare two arrays
function CompareArrays
{
  argArray1=("${!2}")
  argArray2=("${!3}")
  for ((i = 0; i < $1; i++))
  {
    [ "$debug" -ne 0 ] && echo "$i: '${argArray1[$i]}' '${argArray2[$i]}'"
    [ "${argArray1[$i]}" == "${argArray2[$i]}" ] && return 1
  }
  return 0
}

# main function
while (( "$#" )); do

  # option argument
  if [ ${1:0:1} = '-' ]; then
    tmp=${1:1}              # strip off leading '-'
    parameter=${tmp%%=*}    # extract name
    value=${tmp##*=}        # extract value
    eval $parameter=$value

  else

    if [ -e "$1" ]; then
      if [ -z "$infile" ]; then
        infile="$1"	# it's an applicants list file
      else
        echo "$USAGE"
        break;
      fi
    elif [[ $1 =~ ^[-+]?[0-9]+$ ]]; then
      N="$1"		# it's a number to select.
    else
      echo "'$1': invalid number"
    fi

  fi

  shift

done

# check applicant file and number
[ -z "$infile" ] && echo "No Applicants list file" && exit 1
[ "$N" -le 0 ] && echo "'$N': invalid number" && exit 2

# validate the number N
total=$(wc "$infile" | awk '{ print $1 }')
[ "$total" -le "$N" ] && echo "N($N) is larger than the total($total)." && exit 3

# Do the task
[ "$debug" -ne 0 ] && echo "infile=$infile"
[ "$debug" -ne 0 ] && echo "Total=$total N=$N"

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

exit 0
