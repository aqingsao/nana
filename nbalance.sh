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

echo ""
echo "[Busiest]"
echo "Request Count/ Percentage/ Response Time/req \t upstream server"
less $file | awk '{upServer=$13;upTime=$12;if(upServer == "-"){upServer="Nginx"};if(upTime == "-"){upTime=0};upTimes[upServer]+=upTime;count[upServer]++;totalCount++;} END{for(server in upTimes){printf("%s %s%s %sms %s\n", count[server], count[server]/totalCount * 100, "%", 1000*upTimes[server]/count[server], server)}}' | sort -nr

