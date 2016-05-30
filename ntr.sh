#!/bin/sh

function printHelp()
{
    echo "Usage:"
    echo "-h: usage"
    echo "-n: count of lines to show"
    echo ""
}

lineCount=10
while getopts ":nh" optname
  do
    case "$optname" in
      "n")
        lineCount=$OPTARG
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

# m: max; a: average; c: count
# S: second; U: url; R: request; T: total; US: up server
# 
echo "Traffic and Rate Summary: "

read bytesTotal avgBytesByR avgRateByS maxRateS maxRateByS maxBytesU maxBytesByU avgTimeByR <<< `less $file | awk -v limit=3 '
{sec =$4;time=$11; bytes=$10; split($7,urls,"?"); url=urls[1];code=$9;
    countTotal++;timeTotal+=time; bytesTotal+=bytes; 
    countByS[sec]++; countByU[url]++; countByIp[ip]++;
    bytesByS[sec]+=bytes; bytesByU[url]+=bytes;
    timeByS[sec]+=time;timeByU[url]+=time;
    ut=$12; us=$13;if(us == "-"){us=""};if(ut=="-"){ut=0};countByUS[us]++;timeByUS[us]+=ut;
    if(code>=200 && code<300){c200++};if(code>=300 && code<400){c300++};if(code>=400 && code<500){c400++};if(code>=500){c500++};
    if(time>=3){slowC++};
} 
END{maxCountS="";maxCountByS=0; 
    avgBytesByR=bytesTotal/countTotal; 
    maxBytesU="";maxBytesByU=0;
    for(u in bytesByU){if(bytesByU[u] > maxBytesByU){maxBytesByU = bytesByU[u]; maxBytesU=u}}; 
    avgRateByS=bytesTotal/timeTotal;maxRateS="";maxRateByS=0;
    for(s in bytesByS){if(timeByS[s] > 0 && bytesByS[s]/timeByS[s] > maxRateByS){maxRateByS = bytesByS[s]/timeByS[s]; maxRateS=s}}; 
    avgTimeByR=timeTotal/countTotal;
    print bytesTotal/1024/1024, avgBytesByR/1024, avgRateByS/1024, maxRateS, maxRateByS/1024, maxBytesU, maxBytesByU/1024/1024, 
        avgTimeByR
        }'
`

echo "      total traffic ${bytesTotal}MB, average traffic ${avgBytesByR}KB/req"
echo "      average rate ${avgRateByS}KB/s, peak rate ${maxRateByS}KB/s at ${maxRateS}"
echo "      average response time ${avgTimeByR}s/req"

echo ""
echo "[Traffic by Seconds]"
echo "Traffic \t Rate \t Moment \t"
less $file | awk '{second=$4;bytes[second]+=$10;time[second]+=$11} END{for(s in bytes){if(time[s] > 0){printf("%sKB %sKB/s %s\n", bytes[s]/1024, bytes[s]/time[s]/1024, s)}}}' | sort -nr | head -n ${lineCount}

echo ""
echo "[Response Size by Urls]"
echo "Traffic \t Traffic/req \t requests count \t url"
less $file | awk '{split($7,urls,"?"); url=urls[1]; print url, $10}' | sed -e 's:.json::' -re 's/[0-9]+([\/| ])/*\1/g' | awk '{requests[$1]++;bytes[$1]+=$2} END{for(url in requests){printf("%s %s %s %s\n", bytes[url], bytes[url] /requests[url], requests[url], url)}}' | sort -nr | head -n ${lineCount} | awk '{printf("%sMB %sKB/req %s %s\n", $1/1024/1024, $2/1024, $3, $4)}'

echo ""
echo "[Response time by Url]"
echo "Total Time \t Response Time/req \t requests count \t url"
less $file | awk '{split($7,urls,"?"); url=urls[1]; print url, $11}' | sed -e 's:.json::' -re 's/[0-9]+([\/| ])/*\1/g' | awk '{requests[$1]++;time[$1]+=$2} END{for(url in requests){printf("%s %s %s %s\n", time[url], time[url] /requests[url], requests[url], url)}}' | sort -nr | head -n ${lineCount}| awk '{printf("%smin %ss/req %s %s\n", $1/60, $2, $3, $4)}'

echo ""
echo "[Response time Trends]"
echo "Moment \t requests count \t Response Time/req \t Reponse Size"
less $file | awk '{hour=substr($4,2,14);bytes[hour]+=$10;time[hour]+=$11;requests[hour]++} END{for(h in bytes){if(time[h] > 0){printf("%s %s %ss %sMB\n", h, requests[h], time[h]/requests[h], bytes[h]/1024/1024)}}}' | sort -n

