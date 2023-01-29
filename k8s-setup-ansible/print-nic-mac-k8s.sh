#!/bin/bash

DATA="host,k8s mac\n"
for HOST in $(vagrant status | grep "^k8s-" | awk '{print $1}'); do 
    DATA="${DATA}${HOST},$(vagrant ssh $HOST -- ip a|grep -B1 '10.240.10' | head -1 | awk '{print $2}')\n"    
done

echo -e ${DATA} | column -s','