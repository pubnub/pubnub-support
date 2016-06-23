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

args = sys.argv

sub_key  = args[1]
channels = args[2].split(",")
gwtype   = args[3]
markup = args[4]

print ""

for channel in channels:
	url = 'http://storageweb2.us-east-1.pubnub.com:9000/admin-push/sub-key/' + sub_key + '?channel=' + channel + '&type='+ gwtype

	r = requests.get(url)

	print ""

	if markup:
		print "*%s*" % channel

	tokens = json.loads(r.content)

	for token in tokens:
		if markup:
		    print "* %s" % token
		else:
			print "%s,%s" % (channel, token)


# Open a file
fo = open("foo.txt", "rw+")
print "Name of the file: ", fo.name

# Assuming file has following 5 lines
# This is 1st line
# This is 2nd line
# This is 3rd line
# This is 4th line
# This is 5th line

line = fo.readline()
print "Read Line: %s" % (line)

line = fo.readline(5)
print "Read Line: %s" % (line)

# Close opend file
fo.close()
