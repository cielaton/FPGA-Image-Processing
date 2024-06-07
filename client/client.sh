#!/usr/bin/env bash

tty=/dev/ttyUSB0

stty -F $tty 9600 -echo
while read -rs -n 1 receivedLine && [[ $receivedLine != 'q' ]]; do
  echo "Reading"
  echo "read <$receivedLine>" # Replace this with code to handle the characters read
done <$tty
