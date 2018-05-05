#!/bin/bash

pnt=$(curl http://ps.pndsn.com/time/0)
pntt=${pnt:1:10}
echo "pubnub time: $pntt"

syst=$(date +"%s")
echo "system time: $syst"

# systt=$(echo "($syst*10000000)" | bc)
# echo "$systt"

result=$(echo "($pntt-$syst)"*1000 | bc)

# $ echo "$(($a + 1))"
echo "your clock is off by $result seconds"
