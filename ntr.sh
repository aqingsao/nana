#!/bin/sh

function printHelp()
{
    echo "Usage:"
    echo "-h: usage"
    echo "-n: count of lines to show"
    echo ""
}

lineCount=10
while getopts ":hrt" optname
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

ipCount=`less $file | awk '{print $1}' | sort | uniq | wc -l`
slowIpCount=`less $file | awk -v limit="$seconds" '{if($11>limit){print $1}}' | sort | uniq | wc -l`

# m: max; a: average; c: count
# S: second; U: url; R: request; T: total; US: up server
# 
read bytesTotal avgBytesByR avgRateByS maxRateS maxRateByS maxBytesU maxBytesByU avgTimeByR maxTimeU maxTimeByU maxAvgTimeU maxAvgTimeByU<<< `less $file | awk -v limit=3 '
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
    avgTimeByR=timeTotal/countTotal;maxTimeU="";maxTimeByU=0;maxAvgTimeU="";maxAvgTimeByU=0;
    for(u in timeByU){if(timeByU[u] > maxTimeByU){maxTimeByU = timeByU[u]; maxTimeU=u}; if(timeByU[u]/countByU[u] > maxAvgTimeByU){maxAvgTimeByU=timeByU[u]/countByU[u]; maxAvgTimeU=u}}; 
    print bytesTotal/1024/1024, avgBytesByR/1024, avgRateByS/1024, maxRateS, maxRateByS/1024, maxBytesU, maxBytesByU/1024/1024, 
        avgTimeByR, maxTimeU, maxTimeByU, maxAvgTimeU, maxAvgTimeByU
        }'
`

echo "Traffic and Rate Summary: "
echo "      total traffic ${bytesTotal}MB, average traffic ${avgBytesByR}KB/req, max traffic ${maxBytesByU}MB of url ${maxBytesU}"
echo "      average rate ${avgRateByS}KB/s, peak rate ${maxRateByS}KB/s at ${maxRateS}"
echo "      average response time ${avgTimeByR}s/req, max response time ${maxTimeByU}s of url ${maxTimeU}, slowest response time ${maxAvgTimeByU}s/req of url ${maxAvgTimeU}"

echo ""
echo "[Traffic by Seconds]"
echo "Traffic \t Rate \t Moment \t"
less $file | awk '{second=$4;bytes[second]+=$10;time[second]+=$11} END{for(s in bytes){if(time[s] > 0){printf("%s %s %s\n", bytes[s], bytes[s]/time[s], s)}}}' | sort -nr | head -n ${lineCount} | awk '{printf("%sKB %sKB/s %s\n", $1 / 1024, $2 / 1024, $3)}'

echo ""
echo "[Rate by Seconds]"
echo "Rate \t Traffic \t Moment \t"
less $file | awk '{second=$4;bytes[second]+=$10;time[second]+=$11} END{for(s in time){if(time[s] > 0){printf("%s %s %s\n", bytes[s]/time[s], bytes[s], s)}}}' | sort -nr | head -n ${lineCount} | awk '{printf("%sKB/s %sKB %s\n", $1 / 1024, $2 / 1024, $3)}'

echo ""
echo "[Total Response Size by Urls]"
echo "Traffic \t Traffic/req \t requests count \t url"
less $file | awk '{printf("%s?%s\n", $10,$7)}' | awk -F '?' '{url=$2; requests[url]++;bytes[url]+=$1} END{for(url in requests){printf("%s %s %s %s\n", bytes[url] / 1024 / 1024, bytes[url] /requests[url] / 1024, requests[url], url)}}' | sort -nr | head -n 10 | awk '{printf("%sMB %sKB %s %s\n", $1, $2, $3, $4)}'

echo ""
echo "[Average Response Size by Url]"
echo "Response Size/req \t Total Response Size \t requests count \t url"
less $file | awk '{printf("%s?%s\n", $10,$7)}' | awk -F '?' '{url=$2; requests[url]++;bytes[url]+=$1} END{for(url in requests){printf("%s %s %s %s\n", bytes[url] /requests[url] / 1024, bytes[url] / 1024 / 1024, requests[url], url)}}' | sort -nr | head -n 10 | awk '{printf("%sKB %sMB %s %s\n", $1, $2, $3, $4)}'

echo ""
echo "[Total response time by Url]"
echo "Total Time \t Response Time/req \t requests count \t url"
less $file | awk '{printf("%s?%s\n", $11,$7)}' | awk -F '?' '{requests[$2]++;times[$2]+=$1} END{for(i in requests){printf("%s %s %s %s\n", times[i], times[i] /requests[i], requests[i], i)}}' | sort -nr | head -n 10 | awk '{printf("%ss %ss %s %s\n", $1, $2, $3, $4)}'

echo ""
echo "[Average response time by Url]"
echo "Response Time/req \t Total Time \t requests count \t url"
less $file | awk '{printf("%s?%s\n", $11,$7)}' | awk -F '?' '{requests[$2]++;times[$2]+=$1} END{for(i in requests){printf("%s %s %s %s\n", times[i] /requests[i], times[i], requests[i], i)}}' | sort -nr | head -n 10 | awk '{printf("%ss %ss %s %s\n", $1, $2, $3, $4)}'
