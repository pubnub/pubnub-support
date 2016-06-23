# usage
# python devices.py <sub-key> <channels> <push-type>
#
# sub-key: the sub-key value
# channels: comma delimited list of channels; no whitespace
# push-type: apns or gcm
#
# example: python devices.py demo-36 foo,bar apns
# output:  outlined list by channel, by devices with markup ready for Desk response
# 
# *foo*
# * token1
# * token2
# * token3
#
# *bar*
# * token2
# * token5

import requests
import json
import sys
import os
import os.path
import urllib

# args = sys.argv
# sub_key  = args[1]
# channels = args[2].split(",")
# gwtype   = args[3]

sub_key = raw_input("Enter sub-key: ").strip()
infile = raw_input("Enter path to source file: ")
outfile = raw_input("Enter path to output file (current file will be deleted): ")
gwtype = raw_input("'apns' or 'gcm': ")

for x in range(10):
    print '{0}\r'.format(x),
print

print ""
if os.path.isfile(outfile):
	print "deleting output file: %s" % (outfile)
	os.remove(outfile)

print "opening file: %s for writing" % (outfile)
output_file = open(outfile, 'w')
i = 0

with open(infile) as input_file:
    for channel in input_file:
		i = i+1
		# print 'processing channel: {0}\r'.format(i),
		url = 'http://storageweb2.us-east-1.pubnub.com:9000/admin-push/sub-key/' + sub_key + '?' + 'channel=' + urllib.quote_plus(channel.rstrip('\n')) + '&type='+ gwtype
		# print "url: %s" % url
		r = requests.get(url)
 		tokens = json.loads(r.content)
 		print "%d: %s" % (i, r.content)

 		if tokens:
 			print "got tokens"
			for token in tokens:
			    output_file.write(channel + ',' + token + '\n')

print ""
print "completed"
print ""

