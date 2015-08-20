#!/bin/bash

# functions

# function list array
function ShowArray
{
  argArray=("${!2}")
  for ((i = 0, j = 1; i < "$1"; i++, j++))
  {
    printf "%2d: %s\n" "$j" "${argArray[$i]}"
  }
}

# compare two arrays
function CompareArrays
{
  argArray1=("${!2}")
  argArray2=("${!3}")
  for ((i = 0; i < $1; i++))
  {
    [ "${argArray1[$i]}" == "${argArray2[$i]}" ] && return 1
  }
  return 0
}

# Show two arrays
function ShowArrays
{
  argArray1=("${!2}")
  argArray2=("${!3}")
  for ((i = 0, j = 1; i < "$1"; i++, j++))
  {
    printf "%2d: %s %s\n" "$j" "'${argArray1[$i]}'" "'${argArray2[$i]}'"
  }
  return 0
}

# function list array
function DumpArray
{
  echo -n "" > "$1"
  argArray=("${!3}")
  for ((i = 0; i < "$2"; i++))
  {
    if [ ! -z "${argArray[$i]}" ]; then
      echo "${argArray[$i]}" >> "$1"
    fi
  }
}

# function list array
function DumpDraw
{
  echo -n "" > "$1"
  argArray=("${!3}")
  for ((i = 0, j = 1; i < "$2"; i++, j++))
  {
    printf "%2d: %s\n" "$j" "${argArray[$i]}" >> "$1"
  }
}

# group relasted functions

# variables
GRP_N=" N "
GRP_S=" S "
GRP_D=" D "

# count # of group entries in the given file.
function CountGroupEntries
{
  n=$(grep "$2" "$1" | wc | awk '{ print $1 }')
  echo "$n"
}

# count # of group entries in the given file.
function CountOtherGroupEntries
{
  argArray=("${!1}")
  for ((i = 0, n = 0; i < 3; i++))
  {
    if [ $i -ne $2 ]; then
      n=`expr $n + ${argArray[$i]}`
    fi
  }
  echo "$n"
}

# identify group ID
function GroupID
{
  str=${1/$GRP_N/};
  if [ "$str" != "$1" ]; then
    echo "0"	# Group N
  else
    str=${1/$GRP_S/};
    if [ "$str" != "$1" ]; then
      echo "1"	# Group S
    else
      echo "2"	# Group D
    fi
  fi
}

# is power of 2
function IsPower2
{
  result="1"
  for ((x = 2; x < $1; x *= 2))
  {
     if [ `expr $1 % $x` -ne 0 ]; then
       result="0"
       break;
     fi
  }
  echo "$result"
}

# get leap number
function GetLeap
{
  argArray=("${!1}")
  idx=$2
  for ((n = $4; $n >= 1; n /= 2))
  {
    i=`expr $idx + $n`;
    [ `expr $i - $3` -lt 0 -a "${argArray[$i]}" == "0" ] && break;

    (( n *= -1 )); i=`expr $idx + $n`;
    [ `expr $i - $3` -lt 0 -a "${argArray[$i]}" == "0" ] && break;

    (( n *= -1 ));

    [ "$n" == "1" ] && n=-1
  }
  echo "$n"
}

# make a draw with seeders
function MakeSeedDraw
{
  argArray=("${!1}")
  drawTotal=$2
  N=`expr $drawTotal / 2`

  # initialize Draw array
  for ((i = 0; i < $drawTotal; i++))
  {
    argArray[$i]=0;
  }

  # fill the draw with seeders
  leap=0	# jump to
  last=0;	# last index
  lastN=$N;	# magic
  for ((i = 0, j = 1; i < $N; i++, j++))
  {
    idx=`expr $last + $leap`
    (( idx %= $drawTotal ))
    argArray[$idx]="$j"
    (( k = $idx + 1 ))
    argArray[$k]=`expr $drawTotal - $j + 1`

    if [ `expr $j % 2` -eq 1 ]; then
      leap=$N
    else
      result=$(IsPower2 $j)
      if [ "$result" == "1" ]; then
        (( lastN /= 2 ))
        leap=$lastN
      else
        if [ `expr $idx - $N` -ge 0 ]; then
          leap=$(GetLeap "argArray[@]" $idx $drawTotal `expr $N / 2`)
        else
          leap=$(GetLeap "argArray[@]" $idx $N `expr $N / 2`)
        fi
      fi
    fi
    last=$idx
  }
}
