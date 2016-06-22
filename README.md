# About nana
Nana is a lightweight Nginx log analyzer, helping to collect performance metrics and identify performance bottlenecks. It's written in pure shell scripts without dependency of additional libraries.

# Usages
Nana provides a list of available commands with usage:

    <command>.sh [options] <logfile>

Where 'logfile' is the location of nginx log file;

#### Page visits
`npv.sh <logfile>`

Example output:

    Page Visits Summary:
      total 1080577, average 14.0963/s
      peak 182/s at 10/Apr/2016:12:53:20
      max count 218133 of url /api/a.json
    [Busiest Moments By Seconds]
    Page Visits \t Response Size \t Time Spent/req \t Moment \t
    3270 3702KB 0.200978 10/Apr/2016:12:00
    2602 6094.8KB 0.15854 10/Apr/2016:16:47
    [Busiest Urls]
    Page Visits \t Page Size/req \t url \t
    218133 0.334938KB /page/a
    85953 0.0575728KB /api/a.json

#### Traffic and rate
`ntr.sh <logfile>`

Example output:

    Traffic and Rate Summary:
      total traffic 2317.06MB, average traffic 2.19574KB/req
      average rate 14.827KB/s, peak rate 21961.9KB/s at [10/Apr/2016:20:34:37
      average response time 0.148091s/req

    [Traffic by Seconds]
    Traffic      Rate    Moment
    3463.64KB 19.5084KB/s [10/Apr/2016:12:53:17
    3419.21KB 5.13934KB/s [10/Apr/2016:12:53:20

    [Response Size by Urls]
    Traffic      Traffic/req     requests count      url
    372.365MB 8.51443KB/req 44783 /page/a
    126.335MB 3.04758KB/req 42449 /api/a/*

    [Response time by Url]
    Total Time   Response Time/req   requests count      url
    393.592min 12.8345s/req 1840 /page/a
    132.288min 0.186984s/req 42449 /api/a/*

#### Agents
`nagent.sh <logfile>`

Example output:

    Total: 17995
    iPhone: 9332 0.518588
    Android: 5249 0.291692
    spider: 655 0.036399
    iPad: 174 0.00966935
    Windows: 1453 0.0807447
    Mac: 41 0.00227841

    [Spider Details]
    365 Googlebot/2.1;
    81 Baiduspider/2.0;

    [iPhone Version Details]
    5465 9_3_2
    674 8_2

    [Android Version Details]
    2491 4.4.2;
    458 6.0;

#### Upstream servers
`nbalance.sh <logfile>`

Example output:

    665213 67.1366% 113.35ms server1
    245321 24.759% 58.2047ms server2


#### Response code
`ncode.sh <logfile>`

Example output:

    Response Code Summary:
      OK:  981405 out of 1080577
      3XX: 92260
      4XX: 6808
      5XX: 74

    [3XX]
    Requests count   url
    20310 /page/a.html
    14113 /page/b.html

    [4XX]
    Requests count   url
    1228 /page/c.html
    552 /page/d.html

    [5XX]
    Requests count   url
    18 /page/e.html
    11 /page/f.html

#### Slow requests
`nslow.sh <logfile>`

Options:

    -l: time limit, with a default value of 2
    -v: invert match, only show lines that not match specified patterns

Example output: 

    3.049s 0B [104.236.48.XX] [08/Jun/2016:03:54:32] /page/a
    3.550s 12B [10.45.41.XX] [08/Jun/2016:04:00:07] /api/b

# FAQ

#### 1. Print nothing?
Please check log_format of http module in your nginx configurations file(/etc/nginx/nginx.conf), which should be in the following format:

    $remote_addr - $remote_user [$time_local] "$request" $status  $body_bytes_sent $request_time $upstream_response_time $upstream_addr "$http_referer" "$http_user_agent" "$http_x_forwarded_for"';

    // Example: 
    183.63.**.** - - [21/Mar/2016:03:53:41 +0800] "GET /url HTTP/1.1" 200 100759 0.255 0.105 "-" "Mozilla/5.0 (iPhone; CPU iPhone OS 9_1 like Mac OS X) AppleWebKit/601.1.46 (KHTML, like Gecko) Mobile/13B143" "-"

You could use awk to check whether it works:

    less /var/log/ngin/main.log | awk '{print $1}' | head -n 1 // should print ip addresses  
    less /var/log/ngin/main.log | awk '{print $4}' | head -n 1 // should print timestamps  
    less /var/log/ngin/main.log | awk '{print $7}' | head -n 1 // should print urls  
    less /var/log/ngin/main.log | awk '{print $10}' | head -n 1 // should print size of reponse body  
    less /var/log/ngin/main.log | awk '{print $11}' | head -n 1 // should print request time  
    less /var/log/ngin/main.log | awk '{print $13}' | head -n 1 // should print upstream server address

#### 2. sed: illegal option -- r?
Extended regular expression is used in shell scripts, if you encounter such an error, please check to use correct option, such as '-r' in Unix and '-E' in mac.

# TODO List
- [ ] Show percentage of mobile devices (iphone/android/win phone...) and manufactures(Huawei, Samsung, iPhone, Nexus, Letv, HTC, vivo, Xiaomi)
