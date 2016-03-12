import requests
import json
import sys

for arg in sys.argv:
    print arg

args = sys.argv

sub_key = args[1]
channels = args[2].split(",")
gwtype = args[3]

print "channels: %s" % channels

# sub_key = "sub-c-35a3c43a-650a-11e4-8fde-02ee2ddab7fe"
# channel = "54eb45beb5f1e032241c5bf3,54eb45beb5f1e032241c5bf3"
# gwtype = 'apns'

for channel in channels:
	url = 'http://storageweb2.us-east-1.pubnub.com:9000/admin-push/sub-key/' + sub_key + '?channel=' + channel + '&type='+ gwtype

	r = requests.get(url)

	print ""
	print "*%s*" % channel

	tokens = json.loads(r.content)

	for token in tokens:
	    print "* %s" % token
