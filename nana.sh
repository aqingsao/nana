#!/bin/sh

function printHelp()
{
    echo "Usage:"
    echo "-h: usage"
    echo "-a: show all details"
    echo "-p: page visits"
    echo "-r: traffic rate"
    echo "-t: response time"
    echo "-c: response code"
    echo ""
    echo "-i: ip addresses"
    echo "-s: slow queries(over 3 seconds for 8 out of 10 continuous requests)"
    echo ""
}

showUrls=0
showPageVisits=0
showTrafficRate=0
showResponseTime=0
showResponseCode=0
showUpstreamServers=0
showIp=0
showSlowQueries=0
while getopts ":hacprusti" optname
  do
    case "$optname" in
      "h")
        printHelp
        exit 1
        ;;
      "a")
        showPageVisits=1
        showTrafficRate=1
        showResponseTime=1
        showIp=1
        showSlowQueries=1
        showResponseCode=1
        showUpstreamServers=1
        ;;
      "p")
        showPageVisits=1
        ;;
      "r")
        showTrafficRate=1
        ;;
      "u")
        showUpstreamServers=1
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
      "c")
        showResponseCode=1
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

echo "---------Nginx Summary---------"

ipCount=`less $file | awk '{print $1}' | sort | uniq | wc -l`
slowIpCount=`less $file | awk -v limit="$seconds" '{if($11>limit){print $1}}' | sort | uniq | wc -l`

# m: max; a: average; c: count
# S: second; U: url; R: request; T: total; US: up server
# 
read countTotal avgCountByS maxCountS maxCountByS maxCountU maxCountByU bytesTotal avgBytesByR avgRateByS maxRateS maxRateByS maxBytesU maxBytesByU timeTotal avgTimeByR maxAvgTimeS maxAvgTimeByS maxTimeU maxTimeByU maxAvgTimeU maxAvrTimeByU uniqIpCount maxCountIp maxCountByIp c200 c300 c400 c500 upServerC maxCountUS maxCountByUS slowestUS slowestByUS<<< `less $file | awk -v limit=3 'BEGIN{maxTime=0; maxRate=0;maxBytes=0;c200=0;c300=0;c400=0;c500=0;} 
{ip=$1;sec =$4;time=$11; bytes=$10; split($7,urls,"?"); url=urls[1];code=$9;
    countTotal++;timeTotal+=time; bytesTotal+=bytes; 
    countByS[sec]++; countByU[url]++; countByIp[ip]++;
    bytesByS[sec]+=bytes; bytesByU[url]+=bytes;
    timeByS[sec]+=time;timeByU[url]+=time;
    ut=$12; us=$13;if(us == "-"){us=""};if(ut=="-"){ut=0};countByUS[us]++;timeByUS[us]+=ut;
    if(code>=200 && code<300){c200++};if(code>=300 && code<400){c300++};if(code>=400 && code<500){c400++};if(code>=500){c500++}
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
    upServerC=length(countByUS)-1;maxCountUS="";maxCountByUS=0;slowestUS="";slowestByUS=0;
    for(us in countByUS){if(us != "" && countByUS[us]>maxCountByUS){maxCountByUS=countByUS[us];maxCountUS=us};if(us != "" && timeByUS[us]/countByUS[us]>slowestByUS){slowestByUS=timeByUS[us]/countByUS[us];slowestUS=us;}}

    print countTotal, avgCountByS, maxCountS, maxCountByS, maxCountU, maxCountByU, 
        bytesTotal/1024/1024, avgBytesByR/1024, avgRateByS/1024, maxRateS, maxRateByS/1024, maxBytesU, maxBytesByU/1024/1024, 
        timeTotal, avgTimeByR, maxAvgTimeS, maxAvgTimeByS, maxTimeU, maxTimeByU, maxAvgTimeU, maxAvrTimeByU,
        uniqIpCount, maxCountIp, maxCountByIp,
        c200, c300,c400,c500,
        upServerC,maxCountUS,maxCountByUS,slowestUS,slowestByUS
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
echo "response code(-c for detail): "
echo "      OK:  ${c200} out of ${countTotal}"
echo "      3XX: ${c300}"
echo "      4XX: ${c400}"
echo "      5XX: ${c500}"
echo "upstream servers(-u for detail):"
echo "      upstream server count ${upServerC}"
echo "      Busiest server ${maxCountUS} with ${maxCountByUS} requests"
echo "      Slowest server ${slowestUS} with average response time ${slowestByUS}s"
echo "ip addresses(-i for detail): "
echo "      unique ip addresses count ${uniqIpCount}"
echo "      max requests ${maxCountByIp} from ip ${maxCountIp}"
echo "slow queries(-s for detail): "
echo "---------End of Nginx Summary---------"
# echo "ip addresses: uniq count $ipCount, slow $slowIpCount"
# echo "slow requests(-q), slow $slowReqsCount, rate "

# -p
if [ "${showPageVisits}" = "1" ]; then
    echo ""
    echo "---------Page Visits Details---------"
    echo "[Busiest By Seconds]"
    echo "Page Visits \t Response Size \t Time Spent/req \t Moment \t"
    less $file | awk '{second=$4;requests[second]++; bytes[second]+=$10; times[second]+=$11;} END{for(s in requests){printf("%s %sKB %s %s\n", requests[s], bytes[s] / 1024, times[s]/requests[s], s)}}' | sort -nr | head -n 10
    
    echo ""
    echo "[Busiest By Minutes]"
    echo "Page Visits \t Response Size \t Time Spent/req \t Moment \t"
    less $file | awk '{minute = substr($4, 1, 18); requests[minute]++; bytes[minute]+=$10; times[minute]+=$11;} END{for(m in requests){printf("%s %sMB %ss %s\n", requests[m], bytes[m] / 1024 / 1024, times[m]/requests[m], m)}}' | sort -nr | head -n 10
    
    echo ""
    echo "[Busiest By Url]"
    echo "Page Visits \t Page Size/req \t url \t"
    less $file | awk '{printf("%s?%s\n", $10,$7)}' | awk -F '?' '{requests[$2]++;bytes[$2]+=$1} END{for(i in requests){printf("%s %sKB %s\n", requests[i], bytes[i] / requests[i] / 1024, i)}}' | sort -nr | head -n 10
    echo "---------End of Page Visits Details---------"
    echo ""
fi

# -r
if [ "${showTrafficRate}" = "1" ]; then
    echo ""
    echo "---------Traffic and Rate Details---------"
    echo "[Heaviest Traffic by Seconds]"
    echo "Traffic \t Rate \t Moment \t"
    less $file | awk '{second=$4;bytes[second]+=$10;time[second]+=$11} END{for(s in bytes){printf("%s %s %s\n", bytes[s], bytes[s]/time[s], s)}}' | sort -nr | head -n 10 | awk '{printf("%sKB %sKB/s %s\n", $1 / 1024, $2 / 1024, $3)}'

    echo ""
    echo "[Highest Rate]"
    echo "Rate \t Traffic \t Moment \t"
    less $file | awk '{second=$4;bytes[second]+=$10;time[second]+=$11} END{for(s in time){printf("%s %s %s\n", bytes[s]/time[s], bytes[s], s)}}' | sort -nr | head -n 10 | awk '{printf("%sKB/s %sKB %s\n", $1 / 1024, $2 / 1024, $3)}'

    echo ""
    echo "[Total response size by Url]"
    echo "Total Response Size \t Response Size/req \t requests count \t url"
    less $file | awk '{printf("%s?%s\n", $10,$7)}' | awk -F '?' '{url=$2; requests[url]++;bytes[url]+=$1} END{for(url in requests){printf("%s %s %s %s\n", bytes[url] / 1024 / 1024, bytes[url] /requests[url] / 1024, requests[url], url)}}' | sort -nr | head -n 10 | awk '{printf("%sMB %sKB %s %s\n", $1, $2, $3, $4)}'
    
    echo ""
    echo "[Average response size by Url]"
    echo "Response Size/req \t Total Response Size \t requests count \t url"
    less $file | awk '{printf("%s?%s\n", $10,$7)}' | awk -F '?' '{url=$2; requests[url]++;bytes[url]+=$1} END{for(url in requests){printf("%s %s %s %s\n", bytes[url] /requests[url] / 1024, bytes[url] / 1024 / 1024, requests[url], url)}}' | sort -nr | head -n 10 | awk '{printf("%sKB %sMB %s %s\n", $1, $2, $3, $4)}'
    echo "---------End of Traffic and Rate Details---------"
fi

# -t
if [ "${showResponseTime}" = "1" ]; then
    echo ""
    echo "---------Reponse Time Details---------"
    echo "[Total response time by Url]"
    echo "Total Time \t Response Time/req \t requests count \t url"
    less $file | awk '{printf("%s?%s\n", $11,$7)}' | awk -F '?' '{requests[$2]++;times[$2]+=$1} END{for(i in requests){printf("%s %s %s %s\n", times[i], times[i] /requests[i], requests[i], i)}}' | sort -nr | head -n 10 | awk '{printf("%ss %ss %s %s\n", $1, $2, $3, $4)}'

    echo ""
    echo "[Average response time by Url]"
    echo "Response Time/req \t Total Time \t requests count \t url"
    less $file | awk '{printf("%s?%s\n", $11,$7)}' | awk -F '?' '{requests[$2]++;times[$2]+=$1} END{for(i in requests){printf("%s %s %s %s\n", times[i] /requests[i], times[i], requests[i], i)}}' | sort -nr | head -n 10 | awk '{printf("%ss %ss %s %s\n", $1, $2, $3, $4)}'
    echo "---------End of Reponse Time Details---------"
fi

# -c
if [ "${showResponseCode}" = "1" ]; then
    echo ""
    echo "---------Reponse Code Details---------"
    echo "[3XX]"
    echo "Requests count \t url"
    less $file | awk '{split($7,urls,"?"); url=urls[1];code=$9;if(code>=300 && code<400){codes[url]++};} END{for(u in codes){printf("%s %s\n", codes[u], u)}}' | sort -nr | head -n 10

    echo ""
    echo "[4XX]"
    echo "Requests count \t url"
    less $file | awk '{split($7,urls,"?"); url=urls[1];code=$9;if(code>=400 && code<500){codes[url]++};} END{for(u in codes){printf("%s %s\n", codes[u], u)}}' | sort -nr | head -n 10

    echo ""
    echo "[5XX]"
    echo "Requests count \t url"
    less $file | awk '{split($7,urls,"?"); url=urls[1];code=$9;if(code>=500 && code<600){codes[url]++};} END{for(u in codes){printf("%s %s\n", codes[u], u)}}' | sort -nr | head -n 10
    echo "---------End of Reponse Code Details---------"
fi

# -u
if [ "${showUpstreamServers}" = "1" ]; then
    echo ""
    echo "---------Upstream Server Details---------"
    echo "[Busiest]"
    echo "Request Count/ Percentage/ Response Time/req \t upstream server"
    less $file | awk '{upServer=$13;upTime=$12;if(upServer == "-"){upServer="Nginx"};if(upTime == "-"){upTime=0};upTimes[upServer]+=upTime;count[upServer]++;totalCount++;} END{for(server in upTimes){printf("%s %s%s %ss %s\n", count[server], count[server]/totalCount * 100, "%", upTimes[server]/count[server], server)}}' | sort -nr | head -n 10

    echo ""
    echo "[Slowest]"
    echo "Response Time/req \t Request Count \t upstream server"
    less $file | awk '{upServer=$13;upTime=$12;if(upServer == "-"){upServer="Nginx"};if(upTime == "-"){upTime=0};upTimes[upServer]+=upTime;count[upServer]++;totalCount++;} END{for(server in upTimes){printf("%s %s %s\n", upTimes[server]/count[server], count[server], server)}}' | sort -nr | head -n 10 | awk '{printf("%ss %s %s\n", $1, $2, $3)}'

    echo ""
    echo "[Slow Responses]"
    echo "Response Time/req \t moment \t upstream server \t url"
    less $file | awk -v limit=3 '{upServer=$13;upTime=$12;second=$4;url=$7;if(upTime > limit){printf("%ss %s %s %s\n", upTime, second, upServer, url)}}' | sort -nr | head -n 20
    echo "---------End of Upstream Server Details---------"
fi

# -i
if [ "${showIp}" = "1" ]; then
    echo ""
    echo "---------Ip Addresses Details---------"
    echo "Requests count \t Ip address"
    less $file | awk '{requests[$1]++} END{for(ip in requests){printf("%s %s\n", requests[ip], ip)}}' | sort -nr | head -n 10
    echo "---------End of Ip Addresses Details---------"
fi

# -q
if [ "${showSlowQueries}" = "1" ]; then
    echo ""
    echo "---------slow queries(over 3 seconds for 8 out of 10 continuous requests)---------"
    less $file | awk -v limit=3 '{lines[NR]=$0;time[NR]=$11;slowCount=0;if($11 >= limit && NR >= 10){for(i = 10; i >=0; i--){if(time[NR-i] >= limit){slowCount++}; }}; if(slowCount >=6 ){for(i = 10; i >=0; i--){print lines[NR-i]}}}' | head -n 50
    echo "---------End of Ip Addresses Details---------"
fi
