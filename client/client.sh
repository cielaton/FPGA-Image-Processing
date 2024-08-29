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

while read -rs -N 1 value; do
  # printf "%s" "$(printf "%c" "$value" | xxd -p)"
  IMAGE_DATA+="$(printf "%c" "$value" | xxd -p)"
done <"$INPUT_PORT"

gum style --border double --width 80 --align center --margin "1 2" --padding "1 1" "FPGA Image Processing Client"

while [[ "$IS_NOT_MATCHED" == true ]]; do
  while read -rs -N 1 value; do
    IMAGE_HEADER=$(printf "%c" "$value" | xxd -p)
    break
  done <"$INPUT_PORT"

  echo "Please choose and operation to see the image: "

  OPERATION=$(gum choose "Default" "Increase brightness" "Decrease brightness" "Invert" "Threshold" "Quit")

  case "$OPERATION" in
  "Default")
    if [[ $DEFAULT == [[$IMAGE_HEADER]] ]]; then
      ./convert_to_bmp.sh -o default -i "$IMAGE_DATA"
      viewnior ../images/output/default.bmp
    fi
    ;;
  "Increase brightness")
    if [[ $INCREASE_BRIGHTNESS == [[$IMAGE_HEADER]] ]]; then
      ./convert_to_bmp.sh -o increase_brightness -i "$IMAGE_DATA"
      viewnior ../images/output/increase_brightness.bmp
    fi
    ;;
  "Decrease brightness")
    if [[ $DECREASE_BRIGHTNESS == [[$IMAGE_HEADER]] ]]; then
      ./convert_to_bmp.sh -o decrease_brightness -i "$IMAGE_DATA"
      viewnior ../images/output/decrease_brightness.bmp
    fi
    ;;
  "Invert")
    if [[ $INVERT == [[$IMAGE_HEADER]] ]]; then
      ./convert_to_bmp.sh -o invert -i "$IMAGE_DATA"
      viewnior ../images/output/invert.bmp
    fi
    ;;
  "Threshold")
    if [[ $THRESHOLD == [[$IMAGE_HEADER]] ]]; then
      ./convert_to_bmp.sh -o threshold -i "$IMAGE_DATA"
      viewnior ../images/output/threshold.bmp
    fi
    ;;
  "Quit")
    IS_NOT_MATCHED=false
    ;;
  esac

done
