#!/bin/sh

function printHelp()
{
    echo "Usage:"
    echo "-a: show all details"
    echo "-c: response code"
    echo "-h: usage"
    echo "-i: ip addresses"
    echo "-p: page visits"
    echo "-r: traffic rate"
    echo "-s: slow responses that are probably performance bottlenecks"
    echo "-t: response time statisticss"
    echo "-u: upstream server details"
    echo ""
}

showPageVisits=0
showTrafficRate=0
showResponseTime=0
showResponseCode=0
showUpstreamServers=0
showIp=0
showSlowQueries=0
while getopts ":achiprstu" optname
  do
    case "$optname" in
      "a")
        showPageVisits=1
        showTrafficRate=1
        showResponseTime=1
        showIp=1
        showSlowQueries=1
        showResponseCode=1
        showUpstreamServers=1
        ;;
      "c")
        showResponseCode=1
        ;;
      "h")
        printHelp
        exit 1
        ;;
      "i")
        showIp=1
        ;;
      "p")
        showPageVisits=1
        ;;
      "r")
        showTrafficRate=1
        ;;
      "s")
        showSlowQueries=1
        ;;
      "t")
        showResponseTime=1
        ;;
      "u")
        showUpstreamServers=1
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
read countTotal avgCountByS maxCountS maxCountByS maxCountU maxCountByU bytesTotal avgBytesByR avgRateByS maxRateS maxRateByS maxBytesU maxBytesByU timeTotal avgTimeByR maxAvgTimeS maxAvgTimeByS maxTimeU maxTimeByU maxAvgTimeU maxAvrTimeByU uniqIpCount maxCountIp maxCountByIp c200 c300 c400 c500 upServerC maxCountUS maxCountByUS slowestUS slowestByUS slowC slowP<<< `less $file | awk -v limit=3 'BEGIN{maxTime=0; maxRate=0;maxBytes=0;c200=0;c300=0;c400=0;c500=0;slowC=0;} 
{ip=$1;sec =$4;time=$11; bytes=$10; split($7,urls,"?"); url=urls[1];code=$9;
    countTotal++;timeTotal+=time; bytesTotal+=bytes; 
    countByS[sec]++; countByU[url]++; countByIp[ip]++;
    bytesByS[sec]+=bytes; bytesByU[url]+=bytes;
    timeByS[sec]+=time;timeByU[url]+=time;
    ut=$12; us=$13;if(us == "-"){us=""};if(ut=="-"){ut=0};countByUS[us]++;timeByUS[us]+=ut;
    if(code>=200 && code<300){c200++};if(code>=300 && code<400){c300++};if(code>=400 && code<500){c400++};if(code>=500){c500++};
    if(time>=3){slowC++};
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
    slowP=slowC/countTotal * 100;
    print countTotal, avgCountByS, maxCountS, maxCountByS, maxCountU, maxCountByU, 
        bytesTotal/1024/1024, avgBytesByR/1024, avgRateByS/1024, maxRateS, maxRateByS/1024, maxBytesU, maxBytesByU/1024/1024, 
        timeTotal, avgTimeByR, maxAvgTimeS, maxAvgTimeByS, maxTimeU, maxTimeByU, maxAvgTimeU, maxAvrTimeByU,
        uniqIpCount, maxCountIp, maxCountByIp,
        c200, c300,c400,c500,
        upServerC,maxCountUS,maxCountByUS,slowestUS,slowestByUS,
        slowC,slowP
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
echo "      total requests ${countTotal}, slow requests ${slowC}, percentage ${slowP}%"
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

# -s
if [ "${showSlowQueries}" = "1" ]; then
    echo ""
    echo "---------Slow Queries---------"
    echo "[Caused by Nginx configuration or Limited bandwith]"
    less $file | awk -v limit=2 'BEGIN{line=0;shouldPrint=0;}
        {if($12 == "-" && $11 < limit){next};
        line++;time[line]=$11;upTime[line]=$12;if(upTime[line]=="-"){upTime[line]=0};if(time[line] >= limit && time[line] >= 1.5*upTime[line]){isSlow[line]=1}else{isSlow[line]=0};
        ip[line]=$1;second[line]=$4;method[line]=$6;url[line]=$7;code[line]=$9;size[line]=$10;upServer[line]=$13;agent[line]=$14;
        if(line<10){next};
        recentSlowCount=0;for(i = 9; i >=0; i--){if(isSlow[line-i]==1){recentSlowCount++}};
        if(recentSlowCount<6){
            if(shouldPrint == 1){print("-----------------------");shouldPrint=0;};
        }else{
            if(shouldPrint == 0){for(i = 9; i >=0; i--){printf("%s %ss %ss %s %sB %s %s %s\n",second[line-i],time[line-i],upTime[line-i],code[line-i],size[line-i],ip[line-i],url[line-i],agent[line-i])};shouldPrint=1;}
            else{printf("%s %ss %ss %s %sB %s %s %s\n",second[line],time[line],upTime[line],code[line],size[line],ip[line],url[line],agent[line])}
        }}' | more

    echo "[Caused by upstream servers]"
    less $file | awk -v limit=2 'BEGIN{line=0;shouldPrint=0;}
        {if($12 >0){
        line++;time[line]=$11;upTime[line]=$12;if(upTime[line] >= limit){isSlow[line]=1}else{isSlow[line]=0};
        ip[line]=$1;second[line]=$4;method[line]=$6;url[line]=$7;code[line]=$9;size[line]=$10;upServer[line]=$13;agent[line]=$14;
        if(line<10){next};
        recentSlowCount=0;for(i = 9; i >=0; i--){if(isSlow[line-i]==1){recentSlowCount++}};
        if(recentSlowCount<6){
            if(shouldPrint == 1){print("-----------------------");shouldPrint=0;};
        }else{
            if(shouldPrint == 0){for(i = 9; i >=0; i--){printf("%s %ss %ss %s %sB %s %s %s\n",second[line-i],time[line-i],upTime[line-i],code[line-i],size[line-i],ip[line-i],url[line-i],agent[line-i])};shouldPrint=1;}
            else{printf("%s %ss %ss %s %sB %s %s %s\n",second[line],time[line],upTime[line],code[line],size[line],ip[line],url[line],agent[line])}
        }}}' | more

    echo "[Caused by poor network conditions of clients' mobile phones]"
    less $file | awk -v limit=5 'BEGIN{line=0;shouldPrint=0;}
        {line++;time[line]=$11;upTime[line]=$12;if(upTime[line]=="-"){upTime[line]=0};if(time[line] >= limit && time[line] >= 2*upTime[line]){isSlow[line]=1}else{isSlow[line]=0};
        ip[line]=$1;second[line]=$4;method[line]=$6;url[line]=$7;code[line]=$9;size[line]=$10;upServer[line]=$13;agent[line]=$14;
        if(line<10){next};
        recentSlowCount=0;for(i = 9; i >=0; i--){if(isSlow[line-i]==1){recentSlowCount++}};
        if(recentSlowCount>0 && recentSlowCount <= 3){
            if(shouldPrint == 0){for(i = 9; i >=0; i--){
                    if(isSlow[line-i]){
                        printf("%s %ss %ss %s %sB %s %s %s\n",second[line-i],time[line-i],upTime[line-i],code[line-i],size[line-i],ip[line-i],url[line-i],agent[line-i])
                    };
                }
                shouldPrint=1;
            }
            else{
                if(isSlow[line-i]){
                    printf("%s %ss %ss %s %sB %s %s %s\n",second[line],time[line],upTime[line],code[line],size[line],ip[line],url[line],agent[line])
                };
            }
        }else{
            shouldPrint=0;
        }}' | more

    echo "---------End of Slow Queries---------"
fi
