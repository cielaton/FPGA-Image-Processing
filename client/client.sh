#!/usr/bin/env bash

IS_NOT_MATCHED=true
IMAGE_DATA=""
INCREASE_BRIGHTNESS=31
DECREASE_BRIGHTNESS=32
INVERT=17
THRESHOLD=34
DEFAULT=35

while getopts i: flag; do
  case "${flag}" in
  i) INPUT_PORT=${OPTARG} ;;
  *) INPUT_PORT="" ;;
  esac
done

stty -F "$INPUT_PORT" speed 115200 cs8 cstopb -icrnl

gum style --border double --width 80 --align center --margin "1 2" --padding "1 1" "FPGA Image Processing Client"

while [[ "$IS_NOT_MATCHED" == true ]]; do
while read -rs -N 1 value; do
  IMAGE_HEADER=$(printf "%c" "$value" | xxd -p)
  break
done <"$INPUT_PORT"
BACKUP="../images/input/racoon.bmp"


echo "Please choose and operation to see the image: "

  OPERATION=$(gum choose "Default" "Increase brightness" "Decrease brightness" "Invert" "Threshold" "Quit")

  case "$OPERATION" in
  "Default")
    if [[ $DEFAULT == $IMAGE_HEADER ]]; then
      ./convert_to_bmp.sh -i increase_brightness
      viewnior ../images/input/kodim.bmp
    fi
    ;;
  "Increase brightness")
    if [[ $INCREASE_BRIGHTNESS == $IMAGE_HEADER ]]; then
      ./convert_to_bmp.sh -i increase_brightness
      viewnior ../images/output/increase_brightness.bmp
    fi
    ;;
  "Decrease brightness")
    if [[ $DECREASE_BRIGHTNESS == $IMAGE_HEADER ]]; then
      ./convert_to_bmp.sh -i decrease_brightness
      viewnior ../images/output/decrease_brightness.bmp
    fi
    ;;
  "Invert")
    if [[ $INVERT == $IMAGE_HEADER ]]; then
      ./convert_to_bmp.sh -i invert
      viewnior ../images/output/invert.bmp
    fi
    ;;
  "Threshold")
    if [[ $THRESHOLD == $IMAGE_HEADER ]]; then
      ./convert_to_bmp.sh -i threshold
      viewnior ../images/output/threshold.bmp
    fi
    ;;
  "Quit")
    IS_NOT_MATCHED=false
    ;;
  esac

done
