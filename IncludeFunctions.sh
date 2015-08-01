#!/bin/bash

# functions

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
    [ "${argArray1[$i]}" == "${argArray2[$i]}" ] && return 1
  }
  return 0
}

# Show two arrays
function ShowArrays
{
  argArray1=("${!2}")
  argArray2=("${!3}")
  for ((i = 0; i < $1; i++))
  {
    echo "$i: '${argArray1[$i]}' '${argArray2[$i]}'"
  }
  return 0
}

# function list array
function DumpArray
{
  echo -n "" > "$1"
  argArray=("${!3}")
  for ((i = 0; i < "$2"; i++)); do
  {
    if [ ! -z "${argArray[$i]}" ]; then
      echo "${argArray[$i]}" >> "$1"
    fi
  }
  done
}
