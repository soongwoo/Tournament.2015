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
  echo; echo "second arg=$2"; echo
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
