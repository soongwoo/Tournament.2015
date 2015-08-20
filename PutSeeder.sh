#!/bin/bash

# Select N applicants from the given applicants file.
# (Assume that there are two selection groups such as Group A and Group B.)

OPTION="[-seed=4]"
USAGE="Usage: $0 N"

# check the number of argument
# [ $# -ne 2 ] && echo "$USAGE" && exit 1

# initialize variables
seed=5
total=16
debug=0

# include functions
source "./IncludeFunctions.sh"

# parse the arguments
while (( "$#" )); do

  # option argument
  if [ ${1:0:1} = '-' ]; then
    tmp=${1:1}              # strip off leading '-'
    parameter=${tmp%%=*}    # extract name
    value=${tmp##*=}        # extract value
    eval $parameter=$value

  else

    if [[ $1 =~ ^[-+]?[0-9]+$ ]]; then
      total="$1"            # tournament size
    else
      echo "'$1': invalid number"
    fi

  fi

  shift

done

# get the pivot number for tournament draw
N=1
for ((drawTotal = 1; drawTotal < $total; drawTotal *= 2))
{
  (( N *= 2))
}
(( N = $drawTotal / 2 ))
[ "$debug" -ne 0 ] && echo "Tournament=$drawTotal, N=$N, # of Seeders=$seed"

# initialize Draw array
for ((i = 0; i < $drawTotal; i++))
{
  Draw[$i]=0;
}

# fill the draw with seeders
leap=0	# jump to
last=0;	# last index
lastN=$N;	# magic
for ((i = 0, j = 1; i < $N; i++, j++))
{
  idx=`expr $last + $leap`
  (( idx %= $drawTotal ))
  Draw[$idx]="$j"
  (( k = $idx + 1 ))
  Draw[$k]=`expr $drawTotal - $j + 1`

  if [ `expr $j % 2` -eq 1 ]; then
    leap=$N
  else
    result=$(IsPower2 $j)
    if [ "$result" == "1" ]; then
      (( lastN /= 2 ))
      leap=$lastN
    else
      if [ `expr $idx - $N` -ge 0 ]; then
        leap=$(GetLeap "Draw[@]" $idx $drawTotal `expr $N / 2`)
      else
        leap=$(GetLeap "Draw[@]" $idx $N `expr $N / 2`)
      fi
    fi
  fi
  last=$idx
}

[ "$debug" -ne 0 ] && ShowArray "$drawTotal" "Draw[@]" 

# now, leave the requested seeders only
for ((i = 0; i < $drawTotal; i++))
{
  [ `expr "${Draw[$i]}" - $seed` -gt 0 ] && Draw[$i]=0
}
[ "$debug" -ne 0 ] && ShowArray "$drawTotal" "Draw[@]" 

exit 0
