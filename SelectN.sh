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

# include functions
source "./IncludeFunctions.sh"

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
echo "'$infile': Select $N from $total entries"

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

# select N
selected_applicants=("${shuffled_applicants[@]}")
for ((i = 0, loop = 1; i < $N; loop++))
{
  # show progress
  printf "Select %d entries in %d times\r" "$i" "$loop"

  x=`expr $RANDOM % $total`
  [ -z "${shuffled_applicants[$x]}" ] && continue
  selected_applicants[$i]="${shuffled_applicants[$x]}"
  shuffled_applicants[$x]=""

  (( i++ ))
}
printf "Select %d entries in %d times\n" "$i" "$loop"

[ "$debug" -ne 0 ] && ShowArray "$total" "shuffled_applicants[@]"
ShowArray "$N" "selected_applicants[@]"

# dump the result in files
DumpArray "GroupA" "$N" "selected_applicants[@]"
DumpArray "GroupB" "$total" "shuffled_applicants[@]"

exit 0
