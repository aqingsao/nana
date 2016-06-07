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

Baiduspider; Sogou web spider;JikeSpider;
Applebot; bingbot; MJ12bot;Googlebot;Exabot;yahoo! Slurp;
YandexBot; AhrefsBot

echo "      total traffic ${bytesTotal}MB, average traffic ${avgBytesByR}KB/req"
echo "      average rate ${avgRateByS}KB/s, peak rate ${maxRateByS}KB/s at ${maxRateS}"
echo "      average response time ${avgTimeByR}s/req"

echo ""
echo "[Traffic by Seconds]"
echo "Traffic \t Rate \t Moment \t"
less $file | egrep 'spider|bot' | awk '{name=$17;if(index($15,"spider")>0){name=$15};spiders[name]++} END{for(name in spiders){printf("%s %s\n",spiders[name], name)}';

