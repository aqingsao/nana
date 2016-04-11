#!/bin/sh

function printHelp()
{
    echo "Usage:"
    echo "-h: usage"
    echo "-a: show all details(combination of c/r/u/s/t/i/r/q...)"
    echo "-c: request count(by seconds and by minutes, and by urls)"
    echo "-r: traffic rate(By seconds, by minutes, and by urls)"
    echo "-u: urls(top visited urls)"
    echo "-t: response time"
    echo "-i: ip addresses"
    echo "-r: traffic rate(by seconds and minutes)"
    echo "-q: slow queries(over 3 seconds for 8 out of 10 continuous requests)"
    echo ""
}

showUrls=0
showRequestCount=0
showTrafficRate=0
showIp=0
showSlowQueries=0
while getopts ":crustiqh" optname
  do
    case "$optname" in
      "c")
        showRequestCount=1
        ;;
      "r")
        showTrafficRate=1
        ;;
      "u")
        showUrls=1
        ;;
      "i")
        showIp=1
        ;;
      "q")
        showSlowQueries=1
        ;;
      "a")
        showUrls=1
        showRequestCount=
        showTrafficRate=1
        showIp=1
        showSlowQueries=1
        ;;
      "h")
        printHelp
        exit 1
        ;;
      *) 
        printHelp
        exit 1
        ;;
      \?) 
        echo "Invalid option -$OPTARG"
        printHelp
        exit 1
        ;;
    esac
  done

file="${@: -1}"
if [ "$file" = "" ]; then
  echo "please provide an Nginx log file"
  exit 1;
fi
if [ ! -f $file ]; then
  echo "File $file does not exist";
  exit 1;
fi

echo "---------nginx summary---------"

ipCount=`less $file | awk '{print $1}' | sort | uniq | wc -l`
slowIpCount=`less $file | awk -v limit="$seconds" '{if($11>limit){print $1}}' | sort | uniq | wc -l`


read countTotal, avrCountBySec,maxRCountSec, maxRCountBySec, maxRCountUrl, maxRCountByUrl,  bytesTotal, avrRBytesBySec, maxBytesSec, maxBytesBySec, maxRBytesUrl, maxRBytesByUrl, timeTotal <<< `less $file | awk -v limit=3 'BEGIN{maxTime=0; maxRate=0;maxBytes=0} 
{sec =$4;rTime=$11; rBytes=$10; split($7,urls,"?"); url=urls[1];
    countTotal++;timeTotal+=rTime; bytesTotal+=rBytes; 
    rCountBySec[sec]++; rCountByUrl[url]++; 
    rBytesBySec[sec]+=rBytes; rBytesByUrl[url]+=rBytes;
} 
END{maxRCountSec="";maxRCountBySec=0; 
    for(s in rCountBySec){if(rCountBySec[s] > maxRCountBySec){maxRCountBySec = rCountBySec[s]; maxRCountSec=s}}; 
    avrCountBySec=countTotal/length(rCountBySec);maxRCountUrl="";maxRCountByUrl=0;
    for(u in rCountByUrl){if(rCountByUrl[u] > maxRCountByUrl){maxRCountByUrl = rCountByUrl[u]; maxRCountUrl=u}}; 
    avrRBytesBySec=bytesTotal/timeTotal; maxBytesSec="";maxBytesBySec=0;
    for(s in rBytesBySec){if(rBytesBySec[s] > maxBytesBySec){maxBytesBySec = rBytesBySec[s]; maxBytesSec=s}}; 
    maxRBytesUrl="";maxRBytesByUrl=0;
    for(u in rBytesByUrl){if(rBytesByUrl[u] > maxRCountByUrl){maxRBytesUrl = rBytesByUrl[u]; maxRBytesUrl=u}}; 
    
    print countTotal, avrCountBySec, maxRCountSec, maxRCountBySec, maxRCountUrl, maxRCountByUrl, 
        bytesTotal/1024/1024, avrRBytesBySec/1024, maxBytesSec, maxBytesBySec/1024, maxRBytesUrl, maxRBytesByUrl/1024/1024, 
        timeTotal
        }'
`

# read reqsCount averageReqsPerSec peakReqsPerSec topVisitedUrl countOfTopVisitedUrl rateInK maxRateInK slowReqsCount resTimeAverage maxTimeOfRes bytesTotalInM maxBytesInK maxBytesLine bytesAverageInK <<< `less $file | awk -v limit=3 
# 'BEGIN{maxTime=0; maxRate=0;maxBytes=0} 
# {second =$4;responseTime=$11; responseBytes=$10; split($0,urls,"?"); url=urls[1];
#     totalResponseTime+=responseTime; totalResponseBytes+=responseBytes; 
#     reqsCountPerSec[second]++; responseBytesPerSec[second]=responseBytes;
#     reqsCountPerUrl[url]++; responseBytesPerUrl[url]=responseBytes;
#     if(responseTime>0){rate = responseBytes/responseTime}; 
#     if(responseTime>maxTime){maxTime=responseTime;}; 
#     if(responseTime>limit){slowReqs++}; 
#     if(responseTime > 0 && rate>maxRate){maxRate=rate;}; 
#     if(responseBytes>maxBytes){maxBytes=responseBytes;}; 
# } 
# END{averagereqsCountPerSec=FNR/length(reqsCountPerSec);
#     peakreqsCountPerSec=0; 
#     for(second in reqsCountPerSec){if(reqsCountPerSec[second] > peakreqsCountPerSec){peakreqsCountPerSec = reqsCountPerSec[second]}}; 
#     peakResponseBytesPerSec=0;
#     for(second in responseBytesPerSec){if(responseBytesPerSec[second] > peakResponseBytesPerSec){peakResponseBytesPerSec = responseBytesPerSec[second]}}; 
#     topVisitedUrl="";countOfTopVisitedUrl=0;
#     for(url in reqsCountPerUrl){if(reqsCountPerUrl[url] > countOfTopVisitedUrl){countOfTopVisitedUrl = reqsCountPerUrl[url]; topVisitedUrl=url}}; 
#     print FNR, averagereqsCountPerSec, peakreqsCountPerSec, topVisitedUrl, countOfTopVisitedUrl, 
#         totalResponseBytes /totalResponseTime/1024, maxRate/1024, slowReqs, totalResponseTime/ FNR, maxTime, totalResponseBytes / 1024 / 1024, maxBytes/1024, bytes / FNR / 1024}'
# `

echo "(-c)request count: total $countTotal, average ${avrCountBySec}/s, peak ${maxRCountBySec}/s at ${maxRCountSec}, max count ${maxRCountByUrl} of url ${maxRCountUrl}"
echo "(-r)traffic rate: total ${bytesTotal}MB, average ${avrRBytesBySec}KB/s, max ${maxBytesBySec}KB/s at ${maxBytesSec}, highest traffic ${maxRBytesByUrl}MB of url ${maxRBytesUrl}"
echo "ip addresses: uniq count $ipCount, slow $slowIpCount"
echo "time: average ${resTimeAverage}s, max ${maxTimeOfRes}s"
echo "traffic: total ${bytesTotalInM}MB, max ${maxBytesInK}KB, average ${bytesAverageInK}KB/req"
echo "slow requests(-q), slow $slowReqsCount, rate "
echo ""

# -c
if [ "${showRequestCount}" = "1" ]; then
    echo "---------Request Count(By Seconds)---------"
    echo "Request Count \t Response Size \t Time Spent/req \t Moment \t"
    less $file | awk '{second=$4;requests[second]++; bytes[second]+=$10; times[second]+=$11;} END{for(s in requests){printf("%s %sKB %s %s\n", requests[s], bytes[s] / 1024, times[s]/requests[s], s)}}' | sort -nr | head -n 10
    echo "---------Request Count(By Minutes)---------"
    echo "Request Count \t Total Bytes \t Time Spent/req \t Moment \t"
    less $file | awk '{minute = substr($4, 1, 18); requests[minute]++; bytes[minute]+=$10; times[minute]+=$11;} END{for(m in requests){printf("%s %sMB %ss %s\n", requests[m], bytes[m] / 1024 / 1024, times[m]/requests[m], m)}}' | sort -nr | head -n 10
    echo ""
    echo "---------Request Count(By url)---------"
    echo "Request count \t Page Size/req \t url \t"
    less $file | awk '{printf("%s?%s\n", $10,$7)}' | awk -F '?' '{requests[$2]++;bytes[$2]+=$1} END{for(i in requests){printf("%s %sKB %s\n", requests[i], bytes[i] / requests[i] / 1024, i)}}' | sort -nr | head -n 10
    echo ""
fi

# -r
if [ "${showTrafficRate}" = "1" ]; then
    echo "---------Response size(By Seconds)---------"
    echo "Traffic Total \t Traffic Rate \t Moment \t"
    less $file | awk '{second=$4;bytes[second]+=$10;} END{for(s in bytes){printf("%s %s\n", bytes[s], s)}}' | sort -nr | head -n 10 | awk '{printf("%sKB %sKB %s\n", $1 / 1024, $1 / 1024, $2)}'
    echo "---------Response Size(By Minutes)---------"
    echo "Traffic Total \t Traffic Rate \t Moment \t"
    less $file | awk '{minute = substr($4, 1, 18); bytes[minute]+=$10;} END{for(m in bytes){printf("%s %s\n", bytes[m], m)}}' | sort -nr | head -n 10 | awk '{printf("%sMB %sKB %s\n", $1 / 1024 / 1024, $1 / 60 / 1024, $2)}'

    echo "---------Response Size(By Total)---------"
    echo "Total Size \t Response Size/req \t requests count \t url"
    less $file | awk '{printf("%s?%s\n", $10,$7)}' | awk -F '?' '{url=$2; requests[url]++;bytes[url]+=$1} END{for(url in requests){printf("%s %s %s %s\n", bytes[url] / 1024 / 1024, bytes[url] /requests[url] / 1024, requests[url], url)}}' | sort -nr | head -n 10 | awk '{printf("%sMB %sKB %s %s\n", $1, $2, $3, $4)}'
    echo "---------Response Size(By Average)---------"
    echo "Total Size \t Response Size/req \t requests count \t url"
    less $file | awk '{printf("%s?%s\n", $10,$7)}' | awk -F '?' '{url=$2; requests[url]++;bytes[url]+=$1} END{for(url in requests){printf("%s %s %s %s\n", bytes[url] /requests[url] / 1024, bytes[url] / 1024 / 1024, requests[url], url)}}' | sort -nr | head -n 10 | awk '{printf("%sMB %sKB %s %s\n", $2, $1, $3, $4)}'
    echo ""
fi

# -t
if [ "${showResponseTime}" = "1" ]; then
    echo "---------Reponse Time(By Total)---------"
    echo "Total Time \t Response Time/req \t requests count \t url"
    less $file | awk '{printf("%s?%s\n", $11,$7)}' | awk -F '?' '{requests[$2]++;times[$2]+=$1} END{for(i in requests){printf("%s %s %s %s\n", times[i], times[i] /requests[i], requests[i], i)}}' | sort -nr | head -n 10 | awk '{printf("%ss %ss %s %s\n", $1, $2, $3, $4)}'
    echo "---------Reponse Time(By Average)---------"
    echo "Total Time \t Response Time/req \t requests count \t url"
    less $file | awk '{printf("%s?%s\n", $11,$7)}' | awk -F '?' '{requests[$2]++;times[$2]+=$1} END{for(i in requests){printf("%s %s %s %s\n", times[i] /requests[i], times[i], requests[i], i)}}' | sort -nr | head -n 10 | awk '{printf("%ss %ss %s %s\n", $2, $1, $3, $4)}'
    echo ""
fi

# -u
if [ "${showUrls}" = "1" ]; then
    echo "---------Top visited urls---------"
    echo "Request count \t Page Size/req \t url \t"
    less $file | awk '{printf("%s?%s\n", $10,$7)}' | awk -F '?' '{requests[$2]++;bytes[$2]+=$1} END{for(i in requests){printf("%s %sKB %s\n", requests[i], bytes[i] / requests[i] / 1024, i)}}' | sort -nr | head -n 10
    echo ""
fi

# # -f
# if [ "${showUrls}" = "1" ]; then
#     echo "\n---------Traffic(By Total)---------"
#     echo "Total Size \t Response Size/req \t requests count \t url"
#     less $file | awk '{printf("%s?%s\n", $10,$7)}' | awk -F '?' '{requests[$2]++;bytes[$2]+=$1} END{for(i in requests){printf("%s %s %s %s\n", bytes[i] / 1024 / 1024, bytes[i] /requests[i] / 1024, requests[i], i)}}' | sort -nr | head -n 10 | awk '{printf("%sMB %sKB %s %s\n", $1, $2, $3, $4)}'
# fi

# -i
if [ "${showIp}" = "1" ]; then
    echo "---------Ip Addresses(visit times)---------"
    ipCount=`less $file | awk '{print $1}' | sort | uniq | wc -l`
    echo "${ipCount} unique ip addresses"
    echo "Requests count \t Ip address"
    less $file | awk '{requests[$1]++} END{for(ip in requests){printf("%s %s\n", requests[ip], ip)}}' | sort -nr | head -n 10
    echo ""
fi

# -q
if [ "${showSlowQueries}" = "1" ]; then
    echo "\n---------slow queries(over 3 seconds for 8 out of 10 continuous requests)---------"
    less $file | awk -v limit=3 '{lines[NR]=$0;time[NR]=$11;slowCount=0;if($11 >= limit && NR >= 10){for(i = 10; i >=0; i--){if(time[NR-i] >= limit){slowCount++}; }}; if(slowCount >=6 ){for(i = 10; i >=0; i--){print lines[NR-i]}}}' | more
    echo ""
fi
