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

showResponseCode=0
showUpstreamServers=0
showIp=0
showSlowQueries=0
while getopts ":achisu" optname
  do
    case "$optname" in
      "a")
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
      "s")
        showSlowQueries=1
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
read uniqIpCount maxCountIp maxCountByIp c200 c300 c400 c500 upServerC maxCountUS maxCountByUS slowestUS slowestByUS slowC slowP<<< `less $file | awk -v limit=3 'BEGIN{maxTime=0; maxRate=0;maxBytes=0;c200=0;c300=0;c400=0;c500=0;slowC=0;} 
{ip=$1;sec =$4;time=$11; bytes=$10; split($7,urls,"?"); url=urls[1];code=$9;
    countTotal++;timeTotal+=time; bytesTotal+=bytes; 
    countByS[sec]++; countByU[url]++; countByIp[ip]++;
    bytesByS[sec]+=bytes; bytesByU[url]+=bytes;
    timeByS[sec]+=time;timeByU[url]+=time;
    ut=$12; us=$13;if(us == "-"){us=""};if(ut=="-"){ut=0};countByUS[us]++;timeByUS[us]+=ut;
    if(code>=200 && code<300){c200++};if(code>=300 && code<400){c300++};if(code>=400 && code<500){c400++};if(code>=500){c500++};
    if(time>=3){slowC++};
} 
END{uniqIpCount=length(countByIp);maxCountIp="";maxCountByIp=0;
    for(ip in countByIp){if(countByIp[ip] > maxCountByIp){maxCountByIp = countByIp[ip]; maxCountIp=ip}}; 
    upServerC=length(countByUS)-1;maxCountUS="";maxCountByUS=0;slowestUS="";slowestByUS=0;
    for(us in countByUS){if(us != "" && countByUS[us]>maxCountByUS){maxCountByUS=countByUS[us];maxCountUS=us};if(us != "" && timeByUS[us]/countByUS[us]>slowestByUS){slowestByUS=timeByUS[us]/countByUS[us];slowestUS=us;}}
    slowP=slowC/countTotal * 100;
    print uniqIpCount, maxCountIp, maxCountByIp,
        c200, c300,c400,c500,
        upServerC,maxCountUS,maxCountByUS,slowestUS,slowestByUS,
        slowC,slowP
        }'
`

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
