# About nana
Nana is an Nginx log analyzer to identify performance bottlenecks. It's written in shell and awk, aiming to be the best Nginx log analyzer.

So far the following metrics are collected:

#### Page visits
- Top 10 moments that have highest page visits
- Top 10 pages that are visited most frequently

#### Traffic and rate
- Top 10 moments that have highest traffic
- Top 10 moments that have fastest rate
- Top 10 urls that have largest total resonse size
- Top 10 urls that have largest average response size

#### Response time
- List top 10 urls that takes longest response time in total
- List top 10 urls that takes longest response time in average

#### Slow requests
- List slow requests, avoiding mistakes caused by poor network conditions of mobile phones.


# Usages
`nana.sh <options> logfile`

Where 'logfile' is the absolute location of nginx log file;

For example: 
`nana.sh /var/log/nginx/main.log`

#### Example output: 

    ---------nginx summary---------  
    page visits(-p for detail):
        total 888510, average 43.7022/s  
        peak 1421/s at [13/Apr/2016:10:47:23  
        max count 203192 of url ***  
    traffic and rate(-r for detail):  
        total traffic 1903.55MB, average traffic 2.19383KB/req  
        highest traffic 292.069MB of url ***  
        average rate 147.204KB/s  
        max rate 9254.88KB/s at [13/Apr/2016:15:17:45  
    response time(-t for detail):  
        total 132412.7s, average 0.149033s/req  
        max total time 12224.93s of url ***  
        slowest response time 12.266s/req of url ***  
        slowest response time 4.50s/req at [13/Apr/2016:09:35:20  
    ip addresses(-i for detail):  
        unique ip addresses count 33413  
        max requests 4689 from ip ***  

#### Options
* -p: show page visits detail
* -r: show traffic and rate details
* -t: show response time detail
* -s: show slow queries


# TODO List
- [ ] List urls that have reponse of 5**/4**/3**
- [ ] Identify moments that traffic rate is limited by bandwith
- [ ] Identify moments that upstream servers are slow
- [ ] Show access frequency of crawlers(google bot, baidu spider, bingbot, MJ12bot, YandexBot)
- [ ] Show market shares of various mobile phones(iphone/android/win phone...); and portions of versions(iPhone 5, 6, 7, 8, 9)/manufactures(Huawei, Samsung, iPhone, Nexus, Letv, HTC, vivo, Xiaomi)


# FAQ
#### 1. How to identify requests that are really slow?
In general there are 3 types of slow requests:
1. Slow reponse from upstream servers;
2. Limited bandwith of physical servers;
3. Poor network condition of mobile phones.

From data of my site, **about 0.5% requests** are slow because of poor network condition, which should be avoided from alerting. This tool identifies a request as slow only if 8 out of 10 succedding requests are slow.

#### 2. Print nothing?
Please check log_format of http module in your nginx configurations file(/etc/nginx/nginx.conf), which should be in the following format:

    $remote_addr - $remote_user [$time_local] "$request" $status  $body_bytes_sent $request_time $upstream_response_time "$http_referer" "$http_user_agent" "$http_x_forwarded_for"';

    // Example: 
    183.63.**.** - - [21/Mar/2016:03:53:41 +0800] "GET /url HTTP/1.1" 200 100759 0.255 0.105 "-" "Mozilla/5.0 (iPhone; CPU iPhone OS 9_1 like Mac OS X) AppleWebKit/601.1.46 (KHTML, like Gecko) Mobile/13B143" "-"

You could use awk to check whether it works:

    less /var/log/ngin/main.log | awk '{print $1}' | head -n 1 // should print ip addresses  
    less /var/log/ngin/main.log | awk '{print $4}' | head -n 1 // should print timestamps  
    less /var/log/ngin/main.log | awk '{print $7}' | head -n 1 // should print urls  
    less /var/log/ngin/main.log | awk '{print $10}' | head -n 1 // should print size of reponse body  
    less /var/log/ngin/main.log | awk '{print $11}' | head -n 1 // should print request time  

