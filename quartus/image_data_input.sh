#!/usr/bin/env bash

DATA=""

DATA=$(while read -r line; do
  echo "\x$line"
done <"../images/input/racoon_10.hex")

DATA=$(echo "$DATA" | tr -d '\n\r')

echo -en "$DATA" > /dev/ttyUSB0

echo "$DATA"
