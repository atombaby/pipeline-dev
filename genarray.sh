#!/bin/bash

list=($(awk -F',' '$3 ~ /[0-9]/{print $3}' exampleDatatorun.csv ))

declare -a array

array=""

current=${list[0]}
next=${list[1]}

for (( i=1; i<${#list[@]}; i++ ))
do
        echo "$i - ${list[$i]}"
done

