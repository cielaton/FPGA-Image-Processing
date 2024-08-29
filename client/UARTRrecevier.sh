#!/usr/bin/env bash

while getopts i: flag; do
  case "${flag}" in
  i) INPUT_PORT=${OPTARG} ;;
  *) INPUT_PORT="" ;;
  esac
done

stty -F "$INPUT_PORT" speed 115200 cs8 cstopb -icrnl

while read -rs -N 1 value; do
  printf "%s" "$(printf "%c" "$value" | xxd -p)"
done <"$INPUT_PORT"

