# usage
# python push_channels.py <sub-key> <channels> <push-type>
#
# sub-key: the sub-key value
# tokens: comma delimited list of devices; no whitespace
# push-type: apns or gcm
#
# example: python push_channels.py demo-36 token1,token2 apns
# output:  outlined list by token, by channels with markup ready for Desk response
# 
# *token1*
# * channel1
# * channel2
# * channel3
#
# *token2*
# * channel2
# * channel5

import requests
import json
import sys

args = sys.argv

sub_key  = args[1]
tokens = args[2].split(",")
gwtype   = args[3]

print""

for token in tokens:
	url = 'http://pubsub.pubnub.com/v1/push/sub-key/' + sub_key + '/devices/' + token + '&type='+ gwtype

	r = requests.get(url)

	print ""
	print "*%s*" % token

	channels = json.loads(r.content)

	for channel in channels:
	    print "* %s" % channel
