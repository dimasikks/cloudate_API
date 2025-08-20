#!/bin/bash

request=$(curl -s "https://cloudate.digitalleague.ru/api/client/vms?id=$PROJECT_ID" -H "Token: $CLOUDATE_TOKEN" | jq -c .vms[])

parse_sed3="\-sed3\-" 
parse_sed="(\-at\-|\-sed2\-|\-sed3\-|\-esd\-|sele|storage|test|nexus|gitlab|telegram|\.r|elk|fias|k8s|ranchr|rke|logstash|kibana|grafana|massive|new)"
parse_at_consulting="\-at\-"

touch out

while IFS= read -r vm;
do
	name=$(echo "$vm" | jq -r .name)
	id=$(echo "$vm" | jq -r .id)
	echo "$name:$id" >> out
done <<< "$request"

if [ "$VM_FILE" == "at-consulting" ];
then
	cat out | grep -E "$parse_at_consulting" | awk -F ':' '{print $2}' > at-consulting
fi

if [ "$VM_FILE" == "sed" ];
then
	cat out | grep -Ev "$parse_sed" | awk -F ':' '{print $2}' > sed
fi

if [ "$VM_FILE" == "sed3" ];
then
	cat out | grep -E "$parse_sed3" | awk -F ':' '{print $2}' > sed3
fi

rm out
