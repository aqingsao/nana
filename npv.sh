#!/bin/sh

function printHelp()
{
    echo "Usage:"
    echo "-n: count of lines to show"
    echo "-h: usage"
    echo ""
}

lineCount=10
while getopts "hn:" optname
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
read countTotal avgCountByS maxCountByS maxCountS maxCountByU maxCountU <<< `less $file | awk '
{sec =$4;time=$11; split($7,urls,"?"); url=urls[1];countTotal++; countByS[sec]++; countByU[url]++;} 
END{maxCountS="";maxCountByS=0; 
    for(s in countByS){if(countByS[s] > maxCountByS){maxCountByS = countByS[s]; maxCountS=s}}; 
    avgCountByS=countTotal/length(countByS);maxCountU="";maxCountByU=0;
    for(u in countByU){if(countByU[u] > maxCountByU){maxCountByU = countByU[u]; maxCountU=u}}; 
    print countTotal, avgCountByS, maxCountByS, maxCountS, maxCountByU, maxCountU}'
`

echo "Page Visits Summary: "
echo "      total ${countTotal}, average ${avgCountByS}/s"
echo "      peak ${maxCountByS}/s at ${maxCountS}"
echo "      max count ${maxCountByU} of url ${maxCountU}"

echo ""
echo "[Busiest Moments By Seconds]"
echo "Page Visits \t Response Size \t Time Spent/req \t Moment \t"
less $file | awk '{second=substr($4, 2, 17);reqs[second]++; bytes[second]+=$10; times[second]+=$11;} END{for(s in reqs){printf("%s %sKB %s %s\n", reqs[s], bytes[s] / 1024, times[s]/reqs[s], s)}}' | sort -nr | head -n ${lineCount}

echo ""
echo "[Busiest Moments By Every 5 Minutes]"
echo "Page Visits \t Response Size \t Time Spent/req \t Moment \t"
less $file | awk '{hour=substr($4,2,14);min=substr($4,17,2);min=min-min%5;if(min<10){min=hour":0"min;}else{min=hour":"min}; reqs[min]++; bytes[min]+=$10; times[min]+=$11;} END{totalReqs=0;for(m in reqs){totalReqs+=reqs[m]};avgReqsPerMin=totalReqs/length(reqs);for(m in reqs){printf("%s %s %sMB %ss\n", m,reqs[m], bytes[m] / 1024 / 1024, times[m]/reqs[m])}}' | sort

echo ""
echo "[Busiest Urls]"
echo "Page Visits \t Page Size/req \t url \t"
less $file | awk '{split($7,urls,"?"); url=urls[1]; print url, $10}' | sed -e 's:.json::' -re 's/[0-9]+([\/| ])/*\1/g'  | awk '{reqs[$1]++;bytes[$1]+=$2} END{for(i in reqs){printf("%s %sKB %s\n", reqs[i], bytes[i] / reqs[i] / 1024, i)}}' | sort -nr | head -n ${lineCount}
