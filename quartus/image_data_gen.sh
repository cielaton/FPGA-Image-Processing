#!/usr/bin/env bash

INPUT_FILE="../images/input/racoon.hex"
OUTPUT_FILE="./image_data.v"
WIDTH=400
HEIGHT=200
IMAGE_LENGTH=$((WIDTH*HEIGHT*3))

echo "module image_data #(parameter WIDTH = $WIDTH, HEIGHT = $HEIGHT) (output [WIDTH * HEIGHT * 3 :0] imageData);" >$OUTPUT_FILE

counter=0

while read -r line; do
  printf "assign imageData[%d] = 8'h%s;\n" "$counter" "$line" >>$OUTPUT_FILE
  if ((counter < WIDTH * HEIGHT * 3)); then
    counter=$((counter + 1))
  fi
done <$INPUT_FILE

printf ' endmodule' >>$OUTPUT_FILE
