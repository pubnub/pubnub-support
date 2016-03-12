# usage
# python devices.py <sub-key> <channels> <push-type>
#
# sub-key: the sub-key value
# channels: comma delimited list of channels; no whitespace
# push-type: apns or gcm
#
# example: python devices.py demo-36 foo,bar apns
# output:  outlined list by channel/devices with markup ready for Desk response
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

for arg in sys.argv:
    print arg

args = sys.argv

sub_key  = args[1]
channels = args[2].split(",")
gwtype   = args[3]

print "channels: %s" % channels

for channel in channels:
	url = 'http://storageweb2.us-east-1.pubnub.com:9000/admin-push/sub-key/' + sub_key + '?channel=' + channel + '&type='+ gwtype

	r = requests.get(url)

	print ""
	print "*%s*" % channel

	tokens = json.loads(r.content)

	for token in tokens:
	    print "* %s" % token
