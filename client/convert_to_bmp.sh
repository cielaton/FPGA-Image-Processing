#!/usr/bin/env bash

OPERATION=""
FILE_NAME=""

while getopts i: flag; do
  case "${flag}" in
  i) OPERATION=${OPTARG} ;;
  *) OPERATION="" ;;
  esac
done

case "$OPERATION" in
"increase_brightness")
  convert -brightness-contrast 20x0 ../images/input/kodim.bmp ../images/output/increase_brightness.bmp >/dev/null
  ;;
"decrease_brightness")
  convert -brightness-contrast -20x0 ../images/input/kodim.bmp ../images/output/decrease_brightness.bmp >/dev/null
  ;;
"invert")
  convert ../images/input/kodim.bmp -channel RGB -negate ../images/output/invert.bmp >/dev/null
  convert ../images/output/invert.bmp -colorspace gray ../images/output/invert.bmp >/dev/null
  ;;
"threshold")
  convert ../images/input/kodim.bmp -colorspace gray -channel rgb -threshold 50% +channel ../images/output/threshold.bmp > /dev/null
  ;;
*)
  command ...
  ;;
esac
