#!/bin/sh

if [ "$1" = "" ]; then
  echo "please provide an Nginx log file"
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

# echo "---------nginx summary---------"

# read reqsCount slowReqsCount peakReqsPerSec resTimeAverage maxTimeOfRes bytesTotalInM maxBytesInK maxBytesLine bytesAverageInK rateInK maxRateInK minRateInK <<< `less $file | awk -v limit=$seconds 'BEGIN{maxTime=0; maxRate=0;minRate=9999999; maxBytes=0} {time+=$11; bytes+=$10; if($11>0){rate = $10/$11}; if($11>maxTime){maxTime=$11;}; if($11>limit)    {slowReqs++}; if($11 > 0 && rate>maxRate){maxRate=rate;}; if($11 > 0 && rate<minRate){minRate=rate;}; if($10>maxBytes){maxBytes=$10;}; reqsPerSec[$4]++} END{peakReqsPerSec=0;for(i in reqsPerSec){if(reqsPerSec[i] > peakReqsPerSec){peakReqsPerSec = reqsPerSec[i]}}; print FNR, slowReqs, peakReqsPerSec, time/ FNR, maxTime, bytes / 1024 / 1024, maxBytes/1024, bytes / FNR / 1024, bytes/time/1024, maxRate/1024, minRate/1024}'`

# # echo "Requests: total $reqsCount, slow $slowReqsCount, peak ${peakReqsPerSec}/s"
# echo "Requests: total $reqsCount, average $totalReqs / s, $totalReq /m"
# echo "Slow Requests: total $slowReqsCount, Percent $slowReqsPercentage%"
# echo "Ip addresses: total $ipCount, $reqsPerIp/ip"
# echo "Busy moments: $peakReqsPerSec/s, $peakReqsPerSec/m"

echo "Response time: average ${resTimeAverage}s, max ${maxTimeOfRes}s"

echo "Traffic: total ${bytesTotalInM}MB, max ${maxBytesInK}KB, average ${bytesAverageInK}KB/req"
echo "Transfer rate: average ${rateInK}KB/s, max ${maxRateInK}KB/s, min${minRateInK}KB/s"

# -m
echo "\n---------Busy moments(By Seconds)---------"
echo "Request Count \t Total Bytes \t Time Spent/req \t Moment \t"
less $file | awk '{requests[$4]++; bytes[$4]+=$10; times[$4]+=$11;} END{for(i in requests){printf("%s %s %s %s\n", requests[i], bytes[i] / 1024, times[i]/requests[i], i)}}' | sort -nr | head -n 10
echo "---------Busy moments(By Minutes)---------"
echo "Request Count \t Total Bytes \t Time Spent/req \t Moment \t"
less $file | awk '{minute = substr($4, 1, 18); requests[minute]++; bytes[minute]+=$10; times[minute]+=$11;} END{for(m in requests){printf("%s %sMB %ss %s\n", requests[m], bytes[m] / 1024 / 1024, times[m]/requests[m], m)}}' | sort -nr | head -n 10

# -l
echo "\n---------Top visited urls---------"
echo "Request count \t Page Size/req \t url \t"
less $file | awk '{printf("%s?%s\n", $10,$7)}' | awk -F '?' '{requests[$2]++;bytes[$2]+=$1} END{for(i in requests){printf("%s %sKB %s\n", requests[i], bytes[i] / requests[i] / 1024, i)}}' | sort -nr | head -n 10

# -s
echo "\n---------Response Size(By Total)---------"
echo "Total Size \t Response Size/req \t requests count \t url"
less $file | awk '{printf("%s?%s\n", $10,$7)}' | awk -F '?' '{requests[$2]++;bytes[$2]+=$1} END{for(i in requests){printf("%s %s %s %s\n", bytes[i] / 1024 / 1024, bytes[i] /requests[i] / 1024, requests[i], i)}}' | sort -nr | head -n 10 | awk '{printf("%sMB %sKB %s %s\n", $1, $2, $3, $4)}'
echo "---------Response Size(By Average)---------"
echo "Total Size \t Response Size/req \t requests count \t url"
less $file | awk '{printf("%s?%s\n", $10,$7)}' | awk -F '?' '{requests[$2]++;bytes[$2]+=$1} END{for(i in requests){printf("%s %s %s %s\n", bytes[i] /requests[i] / 1024, bytes[i] / 1024 / 1024, requests[i], i)}}' | sort -nr | head -n 10 | awk '{printf("%sMB %sKB %s %s\n", $2, $1, $3, $4)}'

# -t
echo "\n---------Reponse Time(By Total)---------"
echo "Total Time \t Response Time/req \t requests count \t url"
less $file | awk '{printf("%s?%s\n", $11,$7)}' | awk -F '?' '{requests[$2]++;times[$2]+=$1} END{for(i in requests){printf("%s %s %s %s\n", times[i], times[i] /requests[i], requests[i], i)}}' | sort -nr | head -n 10 | awk '{printf("%ss %ss %s %s\n", $1, $2, $3, $4)}'
echo "---------Reponse Time(By Average)---------"
echo "Total Time \t Response Time/req \t requests count \t url"
less $file | awk '{printf("%s?%s\n", $11,$7)}' | awk -F '?' '{requests[$2]++;times[$2]+=$1} END{for(i in requests){printf("%s %s %s %s\n", times[i] /requests[i], times[i], requests[i], i)}}' | sort -nr | head -n 10 | awk '{printf("%ss %ss %s %s\n", $2, $1, $3, $4)}'

# -f
echo "\n---------Traffic(By Total)---------"
echo "Total Size \t Response Size/req \t requests count \t url"
less $file | awk '{printf("%s?%s\n", $10,$7)}' | awk -F '?' '{requests[$2]++;bytes[$2]+=$1} END{for(i in requests){printf("%s %s %s %s\n", bytes[i] / 1024 / 1024, bytes[i] /requests[i] / 1024, requests[i], i)}}' | sort -nr | head -n 10 | awk '{printf("%sMB %sKB %s %s\n", $1, $2, $3, $4)}'

# -i
echo "\n---------Ip Addresses---------"
ipCount=`less $file | awk '{print $1}' | sort | uniq | wc -l`
echo "${ipCount} unique ip addresses"
echo "IP \t requests count"
less $file | awk '{requests[$1]++} END{for(ip in requests){printf("%s %s\n", ip, requests[ip])}}' | sort -nr | head -n 10

# -q
echo "\n---------slow queries---------"
less $file | awk -v limit=$seconds '{lines[NR]=$0;time[NR]=$11;slowCount=0;if($11 >= limit && NR >= 10){for(i = 10; i >=0; i--){if(time[NR-i] >= limit){slowCount++}; }}; if(slowCount >=6 ){for(i = 10; i >=0; i--){print lines[NR-i]}}}' | more