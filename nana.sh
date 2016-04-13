#!/bin/sh

function printHelp()
{
    echo "Usage:"
    echo "-h: usage"
    echo "-a: show all details"
    echo "-p: page visits"
    echo "-r: traffic rate"
    echo "-t: response time"
    echo "-i: ip addresses"
    echo "-s: slow queries(over 3 seconds for 8 out of 10 continuous requests)"
    echo ""
}

showUrls=0
showPageVisits=0
showTrafficRate=0
showResponseTime=0
showIp=0
showSlowQueries=0
while getopts ":haprist" optname
  do
    echo "$optname"
    case "$optname" in
      "p")
        showPageVisits=1
        ;;
      "r")
        showTrafficRate=1
        ;;
      "t")
        showResponseTime=1
        ;;
      "i")
        showIp=1
        ;;
      "s")
        showSlowQueries=1
        ;;
      "a")
        showPageVisits=1
        showTrafficRate=1
        showResponseTime=1
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

# m: max; a: average; c: count
# S: second; U: url; R: request; T: total
# 
read countTotal avgCountByS maxCountS maxCountByS maxCountU maxCountByU bytesTotal avgBytesByR avgRateByS maxRateS maxRateByS maxBytesU maxBytesByU timeTotal avgTimeByR maxAvgTimeS maxAvgTimeByS maxTimeU maxTimeByU maxAvgTimeU maxAvrTimeByU uniqIpCount maxCountIp maxCountByIp<<< `less $file | awk -v limit=3 'BEGIN{maxTime=0; maxRate=0;maxBytes=0} 
{ip=$1;sec =$4;time=$11; bytes=$10; split($7,urls,"?"); url=urls[1];
    countTotal++;timeTotal+=time; bytesTotal+=bytes; 
    countByS[sec]++; countByU[url]++; countByIp[ip]++;
    bytesByS[sec]+=bytes; bytesByU[url]+=bytes;
    timeByS[sec]+=time;timeByU[url]+=time;
} 
END{maxCountS="";maxCountByS=0; 
    for(s in countByS){if(countByS[s] > maxCountByS){maxCountByS = countByS[s]; maxCountS=s}}; 
    avgCountByS=countTotal/length(countByS);maxCountU="";maxCountByU=0;
    for(u in countByU){if(countByU[u] > maxCountByU){maxCountByU = countByU[u]; maxCountU=u}}; 
    avgBytesByR=bytesTotal/countTotal; 
    maxBytesU="";maxBytesByU=0;
    for(u in bytesByU){if(bytesByU[u] > maxBytesByU){maxBytesByU = bytesByU[u]; maxBytesU=u}}; 
    avgRateByS=bytesTotal/timeTotal;maxRateS="";maxRateByS=0;
    for(s in bytesByS){if(timeByS[s] > 0 && bytesByS[s]/timeByS[s] > maxRateByS){maxRateByS = bytesByS[s]/timeByS[s]; maxRateS=s}}; 
    avgTimeByR=timeTotal/countTotal;maxAvgTimeS="";maxAvgTimeByS=0;maxTimeU="";maxTimeByU=0;maxAvgTimeU="";maxAvrTimeByU=0;
    for(u in timeByU){if(timeByU[u] > maxTimeByU){maxTimeByU = timeByU[u]; maxTimeU=u}; if(timeByU[u]/countByU[u] > maxAvrTimeByU){maxAvrTimeByU=timeByU[u]/countByU[u]; maxAvgTimeU=u}}; 
    for(s in timeByS){if(timeByS[s]/countByS[s] > maxAvgTimeByS){maxAvgTimeByS = timeByS[s]/countByS[s]; maxAvgTimeS=s}}; 
    uniqIpCount=length(countByIp);maxCountIp="";maxCountByIp=0;
    for(ip in countByIp){if(countByIp[ip] > maxCountByIp){maxCountByIp = countByIp[ip]; maxCountIp=ip}}; 

    print countTotal, avgCountByS, maxCountS, maxCountByS, maxCountU, maxCountByU, 
        bytesTotal/1024/1024, avgBytesByR/1024, avgRateByS/1024, maxRateS, maxRateByS/1024, maxBytesU, maxBytesByU/1024/1024, 
        timeTotal, avgTimeByR, maxAvgTimeS, maxAvgTimeByS, maxTimeU, maxTimeByU, maxAvgTimeU, maxAvrTimeByU,
        uniqIpCount, maxCountIp, maxCountByIp
        }'
`

echo "page visits(-p for detail): "
echo "      total ${countTotal}, average ${avgCountByS}/s"
echo "      peak ${maxCountByS}/s at ${maxCountS}"
echo "      max count ${maxCountByU} of url ${maxCountU}"
echo "traffic and rate(-r for detail): "
echo "      total traffic ${bytesTotal}MB, average traffic ${avgBytesByR}KB/req"
echo "      highest traffic ${maxBytesByU}MB of url ${maxBytesU}"
echo "      average rate ${avgRateByS}KB/s"
echo "      max rate ${maxRateByS}KB/s at ${maxRateS}"
echo "response time(-t for detail): "
echo "      total ${timeTotal}s, average ${avgTimeByR}s/req"
echo "      max total time ${maxTimeByU}s of url ${maxTimeU}"
echo "      slowest response time ${maxAvrTimeByU}s/req of url ${maxAvrTimeU}"
echo "      slowest response time ${maxAvgTimeByS}s/req at ${maxAvgTimeS}"
echo "ip addresses(-i for detail): "
echo "      unique ip addresses count ${uniqIpCount}"
echo "      max requests ${maxCountByIp} from ip ${maxCountIp}"
echo "slow queries(-s for detail): "
# echo "ip addresses: uniq count $ipCount, slow $slowIpCount"
# echo "slow requests(-q), slow $slowReqsCount, rate "

# -p
if [ "${showPageVisits}" = "1" ]; then
    echo ""
    echo "---------Page Visits Details---------"
    echo "---------By Seconds:"
    echo "Page Visits \t Response Size \t Time Spent/req \t Moment \t"
    less $file | awk '{second=$4;requests[second]++; bytes[second]+=$10; times[second]+=$11;} END{for(s in requests){printf("%s %sKB %s %s\n", requests[s], bytes[s] / 1024, times[s]/requests[s], s)}}' | sort -nr | head -n 10
    
    echo ""
    echo "---------By Minutes:"
    echo "---------Page Visits \t Response Size \t Time Spent/req \t Moment \t"
    less $file | awk '{minute = substr($4, 1, 18); requests[minute]++; bytes[minute]+=$10; times[minute]+=$11;} END{for(m in requests){printf("%s %sMB %ss %s\n", requests[m], bytes[m] / 1024 / 1024, times[m]/requests[m], m)}}' | sort -nr | head -n 10
    
    echo ""
    echo "---------By Url:"
    echo "---------Page Visits \t Page Size/req \t url \t"
    less $file | awk '{printf("%s?%s\n", $10,$7)}' | awk -F '?' '{requests[$2]++;bytes[$2]+=$1} END{for(i in requests){printf("%s %sKB %s\n", requests[i], bytes[i] / requests[i] / 1024, i)}}' | sort -nr | head -n 10
    echo "---------End of Page Visits Details---------"
    echo ""
fi

# -r
if [ "${showTrafficRate}" = "1" ]; then
    echo ""
    echo "---------Traffic and Rate Details---------"
    echo "---------By Traffic"
    echo "Traffic \t Rate \t Moment \t"
    less $file | awk '{second=$4;bytes[second]+=$10;time[second]+=$11} END{for(s in bytes){printf("%s %s %s\n", bytes[s], bytes[s]/time[s], s)}}' | sort -nr | head -n 10 | awk '{printf("%sKB %sKB/s %s\n", $1 / 1024, $2 / 1024, $3)}'

    echo ""
    echo "---------By Rate"
    echo "Rate \t Traffic \t Moment \t"
    less $file | awk '{second=$4;bytes[second]+=$10;time[second]+=$11} END{for(s in time){printf("%s %s %s\n", bytes[s]/time[s], bytes[s], s)}}' | sort -nr | head -n 10 | awk '{printf("%sKB/s %sKB %s\n", $1 / 1024, $2 / 1024, $3)}'

    echo ""
    echo "---------By Url(total)"
    echo "Total Response Size \t Response Size/req \t requests count \t url"
    less $file | awk '{printf("%s?%s\n", $10,$7)}' | awk -F '?' '{url=$2; requests[url]++;bytes[url]+=$1} END{for(url in requests){printf("%s %s %s %s\n", bytes[url] / 1024 / 1024, bytes[url] /requests[url] / 1024, requests[url], url)}}' | sort -nr | head -n 10 | awk '{printf("%sMB %sKB %s %s\n", $1, $2, $3, $4)}'
    
    echo ""
    echo "---------By Url(average)"
    echo "Response Size/req \t Total Response Size \t requests count \t url"
    less $file | awk '{printf("%s?%s\n", $10,$7)}' | awk -F '?' '{url=$2; requests[url]++;bytes[url]+=$1} END{for(url in requests){printf("%s %s %s %s\n", bytes[url] /requests[url] / 1024, bytes[url] / 1024 / 1024, requests[url], url)}}' | sort -nr | head -n 10 | awk '{printf("%sKB %sMB %s %s\n", $1, $2, $3, $4)}'
    echo "---------End of Traffic and Rate Details---------"
fi

# -t
if [ "${showResponseTime}" = "1" ]; then
    echo ""
    echo "---------Reponse Time Details---------"
    echo "---------By Url(total)"
    echo "Total Time \t Response Time/req \t requests count \t url"
    less $file | awk '{printf("%s?%s\n", $11,$7)}' | awk -F '?' '{requests[$2]++;times[$2]+=$1} END{for(i in requests){printf("%s %s %s %s\n", times[i], times[i] /requests[i], requests[i], i)}}' | sort -nr | head -n 10 | awk '{printf("%ss %ss %s %s\n", $1, $2, $3, $4)}'

    echo ""
    echo "---------By Url(average)"
    echo "Response Time/req \t Total Time \t requests count \t url"
    less $file | awk '{printf("%s?%s\n", $11,$7)}' | awk -F '?' '{requests[$2]++;times[$2]+=$1} END{for(i in requests){printf("%s %s %s %s\n", times[i] /requests[i], times[i], requests[i], i)}}' | sort -nr | head -n 10 | awk '{printf("%ss %ss %s %s\n", $1, $2, $3, $4)}'
    echo "---------End of Reponse Time Details---------"
fi

# -i
if [ "${showIp}" = "1" ]; then
    echo "---------Ip Addresses Details---------"
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
