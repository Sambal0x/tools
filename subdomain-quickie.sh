#!/bin/bash

# Author: Sambal0x
#
# Instructions : ./subdomain-quickie <domain.com>


###############################################  Subdomain Enumeration   ############################################

echo "[+] Running Amass on $1..."
amass enum -d $1 -o $1-subdomains.txt

# Massdns subdomain bruteforce
echo "[+] Bruteforcing $1 with massdns ..."
/opt/external/osint/massdns/scripts/subbrute.py /opt/external/osint/massdns/lists/all.txt $1 \
| massdns -r /opt/external/osint/massdns/lists/working-resolvers.txt -t A -o S -w $1-massdns.txt 2>/dev/null

cat $1-massdns.txt | cut -d " " -f 1 | sed 's/.$//' | sed '/\*/d' >> $1-subdomains.txt
sort -u -o $1-subdomains.txt $1-subdomains.txt  # remove dups in files
echo "[+] Found $(cat $1-subdomains.txt| wc -l) so far ..."

# Run dnsgen to get MORE subdomains
echo "[+] Bruteforcing $1 with dnsgen + massdns ..."
cat $1-subdomains.txt | dnsgen - | massdns -r /opt/external/osint/massdns/lists/working-resolvers.txt -t A -o S -w $1-dnsgen.txt 2>/dev/null
cat $1-dnsgen.txt | cut -d " " -f 1 | sed 's/.$//' | sed '/\*/d' >> $1-subdomains.txt
sort -u -o $1-subdomains.txt $1-subdomains.txt  # remove dups in files
echo "[+] Found $(cat $1-subdomains.txt| wc -l) so far ..."

#############################################  Check for subdomain takeovers ########################################

# Analyse for Subdomain takeover
echo "[+] Now analysing results with Subjack..."
for i in $1-subdomains.txt; do /root/go/bin/subjack -w $i -c /root/go/src/github.com/haccer/subjack/fingerprints.json -o $1-stakeover.txt; done 

# Send results to slack's web hook
echo "[+] Sending results to slack ..."

subdomains="$(cat $1-subdomains.txt)"
curl -X POST -H 'Content-type: application/json' --data "{'text':'## Subdomain for $1 ##\n$subdomains'}" \
	https://hooks.slack.com/services/blahblahblah

takeover="$(cat $1-stakeover.txt)"
curl -X POST -H 'Content-type: application/json' --data "{'text':'## Subdomain Takeover $1 ##\n$takeover'}" \
	https://hooks.slack.com/services/blahblahblah
