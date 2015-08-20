#!/bin/bash

# Revision
# 1.1
# - avoid same group in every 4 slots
# - avoid same group to fill the remaining

# Further changes
# - seed entries: handle it with external file
# - entry file shuffle: need some idea

# create a tournament draw from the given applicants file.

OPTION="[-debug=0] [-seedfile=seed.txt]"
USAGE="Usage: $0 applicants-list-file"

# check the number of argument
# [ $# -ne 1 ] && echo "$USAGE" && exit 1

# initialize variables
N=0
seed=0
debug=0
infile=""
seedfile=""

GRP_N=" N "
GRP_S=" S "
GRP_D=" D "

N_entries=(0 0 0)	# number of entries for Group_N, Group_S and Group_D

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
[ ! -z "$seedfile" -a ! -e "$seedfile" ] && echo "'$seedfile': not found" && exit 2

# total number of applicants
total=$(wc "$infile" | awk '{ print $1 }')
N_entries[0]=$(CountGroupEntries "$infile" "$GRP_N")
N_entries[1]=$(CountGroupEntries "$infile" "$GRP_S")
N_entries[2]=$(CountGroupEntries "$infile" "$GRP_D")

# Do the task
echo "'$infile': $total (${N_entries[@]}) entries"

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

# now, if there is a seed file, adjust tournament size.
if [ ! -z "$seedfile" ]; then
  # make an array for seeders
  mapfile -t Seeders < "$seedfile"

  seed=$(wc "$seedfile" | awk '{ print $1 }')
  if [ `expr $seed + $total` -gt $drawTotal ]; then
    (( drawTotal *= 2))
    (( N *= 2))
  fi
fi

echo "Total entries=$total Draw Total=$drawTotal Seed Total=$seed"

# now, create a tournament draw.

# initialize Draw array
for ((i = 0; i < $drawTotal; i++))
{
  Draw[$i]=0;
}

# now, if there is a seed file, put seeder(s) first.
if [ ! -z "$seedfile" ]; then

  # fill the draw with seeders
  leap=0		# jump to
  last=0		# last index
  lastN=$N	# magic
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
  [ "$debug" -ne 0 ] && echo "* Seed" && ShowArray "$drawTotal" "Draw[@]" 

  # now, leave the requested seeders only
  for ((i = 0; i < $drawTotal; i++))
  {
    if [ `expr "${Draw[$i]}" - $seed` -gt 0 ]; then
      Draw[$i]=0
    else
      j=${Draw[$i]}
      Draw[$i]=${Seeders[`expr $j - 1`]}
    fi
  }
  [ "$debug" -ne 0 ] && echo "* $seed Draw" && ShowArray "$drawTotal" "Draw[@]" 
fi

# select N applicants from shuffled applicants array
j=0
samegrp=0
for ((i = 0, loop = 1; i < $drawTotal; loop++))
{
  # show progress
  printf "Select %d entries in %d times\r" "$j" "$loop"

  x=`expr $RANDOM % $total`
  [ -z "${shuffled_applicants[$x]}" ] && continue
  if [ "${Draw[$i]}" != "0" ]; then
    lastID=-1
    samegrp=0
    (( j++ ))
    (( i++ ))		# a seeder is assigned
    Draw[ ((i++)) ]=""
    lastID=$(GroupID "${Draw[$i]}")
    continue
  fi

  # do not put same group members in every 4 slots.
  entry="${shuffled_applicants[$x]}"
  ID=$(GroupID "$entry")
  if [ `expr $i % 4` -ne 0 ]; then
    left=$(CountOtherGroupEntries "N_entries[@]" $ID)
    if [ $lastID -eq $ID -a "$left" != "0" ]; then
      (( samegrp++ ))
      continue
    fi
  else
    lastID=-1
    samegrp=0
  fi

  (( j++ ))
  Draw[ ((i++)) ]="${shuffled_applicants[$x]}"
  Draw[ ((i++)) ]=""
  shuffled_applicants[$x]=""

  N_entries[$ID]=`expr ${N_entries[$ID]} - 1`
  [ "$debug" -ne 0 ] && printf "Select %d entries in %d times\n" "$j" "$loop"
  [ "$debug" -ne 0 ] && echo "$entry $ID($lastID)=${N_entries[ID]} same group=$samegrp"
  lastID=$ID
 
}
printf "Select %d entries in %d times\n" "$j" "$loop"
[ "$debug" -ne 0 ] && ShowArray "$drawTotal" "Draw[@]"

# now, fill the remaining
loop=0
filled=0
for ((i = 0; i < $total; i++))
{
  # show progress
  printf "Fill %d entries in %d times\r" "$filled" "$loop"

  # already picked?
  [ -z "${shuffled_applicants[$i]}" ] && continue;
  entry="${shuffled_applicants[$i]}"
  ID=$(GroupID "$entry")

  # get an empty draw
  x=0
  samegrp=0
  for ((j = 1; j; j++))
  {
    x=`expr $RANDOM % $drawTotal`	# the index in draw

    # show progress
    (( loop++ ))
    printf "Fill %d entries in %d times\r" "$filled" "$loop"

    # occupied?
    [ ! -z "${Draw[$x]}" ] && continue;

    # alternate the sides
    if [ `expr $filled % 2` -eq 0 ]; then
       [ $x -ge $N ] && continue;
    else
       [ $x -lt $N ] && continue;
    fi

    # avoid same group
    y=`expr $x - 1`
    oppID=$(GroupID "${Draw[$y]}")
    if [ $oppID != $ID ]; then
      break;
    else
      left=$(CountOtherGroupEntries "N_entries[@]" $ID)
      if [ "$left" == "0" ]; then
        break
      else
        (( samegrp++ ))
      fi
    fi
  }

  # fill it
  Draw[$x]="${shuffled_applicants[$i]}"
  shuffled_applicants[$i]=""
  (( filled++ ))

  N_entries[$ID]=`expr ${N_entries[$ID]} - 1`
  [ "$debug" -ne 0 ] && printf "Fill %d entries in %d times\r" "$filled" "$loop"
  [ "$debug" -ne 0 ] && echo "$entry $ID($oppID)=${N_entries[ID]} same group=$samegrp"
}

# check the number of loop
printf "Fill %d entries in %d times\n" "$filled" "$loop"
ShowArray "$drawTotal" "Draw[@]"
DumpDraw "Draw.2015.txt" "$drawTotal" "Draw[@]"
echo "'$infile': $total (${N_entries[@]}) entries"

exit 0
