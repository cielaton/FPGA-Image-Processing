#!/usr/bin/env bash

OPERATION=""
RECEIVED_STRING=""

while getopts o:i: flag; do
  case "${flag}" in
  o) OPERATION=${OPTARG} ;;
  i) RECEIVED_STRING=${OPTARG} ;;
  *) ;;
  esac
done

case "$OPERATION" in
"increase_brightness")
  echo "$RECEIVED_STRING" | bc >../images/output/increase_brightness.bmp
  ;;
"decrease_brightness")
  echo "$RECEIVED_STRING" | bc >../images/output/decrease_brightness.bmp
  ;;
"invert")
  echo "$RECEIVED_STRING" | bc >../images/output/invert.bmp
  ;;
"threshold")
  echo "$RECEIVED_STRING" | bc >../images/output/threshold.bmp
  ;;
*)
  command ...
  ;;
esac
