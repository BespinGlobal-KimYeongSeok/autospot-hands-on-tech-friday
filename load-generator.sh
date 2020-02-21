#!/usr/local/bin/bash
x=1
DNS=$1
while [ $x -le 1000 ]; 
do 
curl -s -o /dev/null $DNS 2>&1;
echo "$x times";
((x=x+1))
done 

