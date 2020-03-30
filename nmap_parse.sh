#!/bin/bash

//https://unix.stackexchange.com/questions/24140/return-only-the-portion-of-a-line-after-a-matching-pattern
//gets the top occurence services from .gnmap files.

cat *.gnmap  | sed -n -e 's/^.*Ports://p' |  grep -oP '(?<= ).*?(?=///)'  | grep open | sort | uniq -c | sort -bgr
