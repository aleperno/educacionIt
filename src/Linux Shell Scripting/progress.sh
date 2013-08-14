#!/bin/bash
for i in $(seq 1 1 100);do
	sleep 0;
	echo $i | dialog --gauge "Please wait" 10 70 0;
	done
