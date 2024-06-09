#!/usr/bin/env bash

DATA=""
INPUT_IMAGE_FILE=$1
INPUT_VERILOG_FILE=$2
OUTPUT_FILE=$3
WIDTH=$4
HEIGHT=$5

echo "The input file is: $INPUT_IMAGE_FILE"

sed -n 1,2p "$INPUT_VERILOG_FILE" >"$OUTPUT_FILE"

echo "parameter WIDTH = 768, HEIGHT = 512," >>"$OUTPUT_FILE"

sed -n 5,75p "$INPUT_VERILOG_FILE" >>"$OUTPUT_FILE"

echo "initial begin" >>"$OUTPUT_FILE"

counter=0
DATA=$(while read -r line; do
  printf "totalMemory[%d] = 8\'h%s;" "$counter" "$line"
  counter=$((counter + 1))
done <"$INPUT_IMAGE_FILE")

DATA=$(echo "$DATA" | tr -d '\n\r')

echo "$DATA" >>"$OUTPUT_FILE"

echo "end" >>"$OUTPUT_FILE"

sed -n 77,\$p "$INPUT_VERILOG_FILE" >>"$OUTPUT_FILE"
