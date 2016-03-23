#!/bin/sh

if [ "$1" = "" ]; then
  echo "please provide a nginx log file in /var/log/nginx/"
  exit 1;
fi

file="$1"
if [ ! -f $file ]; then
  echo "File $file does not exist";
  exit 1;
fi
if [ "$2" = "" ]; then
  seconds=2
else
  seconds=$2
fi

echo "---------nginx summary---------"

ipCount=`less $file | awk '{print $1}' | sort | uniq | wc -l`
slowIpCount=`less $file | awk -v limit="$seconds" '{if($11>limit){print $1}}' | sort | uniq | wc -l`

read reqsCount slowReqsCount resTimeAverage maxTimeOfRes bytesTotalInM maxBytesInK maxBytesLine bytesAverageInK rateInK maxRateInK minRateInK <<< `less $file | awk -v limit=$seconds 'BEGIN{maxTime=0; maxRate=0;minRate=9999999; maxBytes=0} {time+=$11; bytes+=$10; if($11>0){rate = $10/$11}; if($11>maxTime){maxTime=$11;}; if($11>limit)    {slowReqs++}; if($11 > 0 && rate>maxRate){maxRate=rate;}; if($11 > 0 && rate<minRate){minRate=rate;}; if($10>maxBytes){maxBytes=$10;}} END{print FNR, slowReqs, time/ FNR, maxTime, bytes / 1024 / 1024, maxBytes/1024, bytes / FNR / 1024, bytes/time/1024, maxRate/1024, minRate/1024}'`

echo "requests: total $reqsCount, slow $slowReqsCount"
echo "unique ip: total $ipCount, slow $slowIpCount"
echo "time: average ${resTimeAverage}s, max ${maxTimeOfRes}s"
echo "traffic: total ${bytesTotalInM}MB, max ${maxBytesInK}KB, average ${bytesAverageInK}KB/req"
echo "rate: average ${rateInK}KB/s, max ${maxRateInK}KB/s, min${minRateInK}KB/s"

echo "---------slow queries---------"
# 60.000 - 111.161.114.249 [22/Mar/2016:17:35:00 /js/thickbox.js?v1 200 6453 "Mozilla/5.0 (iPhone; CPU
less $file | awk -v limit=$seconds '{lines[NR]=$0;time[NR]=$11;slowCount=0;if($11 >= limit && NR >= 10){for(i = 10; i >=0; i--){if(time[NR-i] >= limit){slowCount++}; }}; if(slowCount >=6 ){for(i = 10; i >=0; i--){print lines[NR-i]}}}'

# less tongshijia.log-20160323 | grep '22/Mar/2016:14:4' | awk '{print $7}' | awk -F '?' '{urls[$1]++}END{for(i in urls){printf("%s %s\n", urls[i], i)}}' | sort -n
