#!/bin/sh

function printHelp()
{
    echo "Usage:"
    echo "-n: count of lines to show"
    echo "-h: usage"
    echo ""
}

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

read countTotal c200 c300 c400 c500 <<< `less $file | awk -v limit=3 'BEGIN{c200=0;c300=0;c400=0;c500=0;} 
{code=$9;countTotal++;
    if(code>=200 && code<300){c200++};if(code>=300 && code<400){c300++};if(code>=400 && code<500){c400++};if(code>=500){c500++};
} 
END{print countTotal, c200, c300,c400,c500}'
`

echo "Response Code Summary: "
echo "      OK:  ${c200} out of ${countTotal}"
echo "      3XX: ${c300}"
echo "      4XX: ${c400}"
echo "      5XX: ${c500}"

echo ""
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
