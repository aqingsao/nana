#!/bin/sh

function printHelp()
{
    echo "Usage:"
    echo "-h: usage"
    echo "-l: time limit in second, default 2"
    echo "-v: invert match, only show lines that not match specified patterns"
    echo ""
}

limit=2
invertMatch="ZZZYYYXXX"
while getopts ":lvh" optname
  do
    case "$optname" in
      "l")
        limit=$OPTARG
        ;;
      "v")
        invertMatch=$OPTARG
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

echo "Slow Queries Summary: "
less $file | grep -v "${invertMatch}" | awk -v limit=${limit} 'BEGIN{slow=0;total=1;};{total++; if($11>=limit){slow++};}END{printf("Slow Requests %s, percentage %s%s\n", slow,slow/total * 100, "%")}'
echo "Ip \t Moment \t Response Time \t Upstream Server Response Time \t Reponse Size \t Url"
less $file | grep -v "${invertMatch}" | awk -v limit=${limit} '{split($7, urls, "?"); url=urls[1];if($11>=limit){printf("%ss %sB [%s] %s] %s\n", $11, $10, $1, $4, url)}}'
