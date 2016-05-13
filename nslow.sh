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
while getopts ":l" optname
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
less $file | grep -v "${invertMatch}" | awk -v limit=${limit} 'BEGIN{slow=0};{total++; if($11>=limit){slow++};}END{printf("Slow Requests %s, percentage %s%s\n", slow,slow/total * 100, "%")}'
echo "Ip \t Moment \t Response Time \t Upstream Server Response Time \t Reponse Size \t Url"
less $file | grep -v "${invertMatch}" | awk -v limit=${limit} '{split($7, urls, "?"); url=urls[1];if($11>=limit){printf("%ss %sB [%s] %s] %s\n", $11, $10, $1, $4, url)}}'

echo ""
echo "[Caused by upstream servers]"
less $file | awk -v limit=${limit} 'BEGIN{line=0;shouldPrint=0;}
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

echo ""
echo "[Caused by Nginx configuration or Limited bandwith]"
less $file | awk -v limit=${limit} 'BEGIN{line=0;shouldPrint=0;}
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


echo "[Caused by poor network conditions of clients' mobile phones]"
less $file | awk -v limit=${limit} 'BEGIN{line=0;shouldPrint=0;}
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
