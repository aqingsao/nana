#!/bin/sh

function printHelp()
{
    echo "Usage:"
    echo "-h: usage"
    echo ""
}

lineCount=10
while getopts ":h" optname
  do
    case "$optname" in
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

less $file | awk -F '"' '{reqs++;if($6~"spider|Spider|bot"){spider++};if($6~"android|Android"){android++};if($6~"iPhone"){iPhone++};if($6~"iPad"){pad++};if($6~"Macintosh"){mac++};if($6~"Windows"){win++}}END{printf("Total: %s \niPhone: %s %s \nAndroid: %s %s\nspider: %s %s \niPad: %s %s\nWindows: %s %s\nMac: %s %s\n", reqs, iPhone, iPhone/reqs, android, android/reqs, spider, spider/reqs, pad, pad/reqs, win, win/reqs, mac, mac/reqs)}'

# spiders
echo ""
echo "[Spider Details]"
less $file | awk -F '"' '{if($6~"spider|Spider|bot"){print $6}}' | awk '{name=$3;if(index($1,"spider")>0){name=$1};types[name]++} END{for(name in types){printf("%s %s\n",types[name], name)}}' | sort -nr

echo ""
echo "[iPhone Version Details]"
less $file | awk -F '"' '{if($6~"iPhone"){print $6}}' | awk '{name=$6;if($6=="OS"){name=$7};types[name]++} END{for(name in types){printf("%s %s\n",types[name], name)}}' | sort -nr

echo ""
echo "[Android Version Details]"
less $file | awk -F '"' '{if($6~"android|Android"){print $6}}' | awk '{name="unknown";if($4~/^([0-9]+\.)+[0-9];?$/){name=$4}if($5~/^([0-9]+\.)+[0-9];?$/){name=$5};types[name]++} END{for(name in types){printf("%s %s\n",types[name], name)}}' | sort -nr

# echo "Android Manufacture Details"
# less $file | awk -F '"' '{if($6~"android|Android"){print $6}}' | awk '{name="unknown";if($6~/^Build\//){name=$6};if($7~/^Build\//){name=$7};types[name]++} END{for(name in types){printf("%s %s\n",types[name], name)}}' | sort -nr
