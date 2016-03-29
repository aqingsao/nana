# About nana
Nana is an Nginx log analyzer to identify performance bottlenecks. It's written in shell and awk, aiming to be the best Nginx log analyzer.

So far the following metrics are collected:
#### Nginx summary
- count of requests and unique ip addresses;
- count of slow requests;
- Total bytes, average bytes per request and transfer rate

#### Busy moments
- List top 10 moments that are visited most frequently

#### Hot urls
- List top 10 urls that are mostly visited

#### Large urls
- List top 10 urls that have largest response size

#### Slow urls
- List top 10 urls that have largest response time

#### Slow requests
- List slow requests, avoiding mistakes caused by poor network conditions of mobile phones.

 
# Usages
`./nana.sh <logfile> [timeLimitInSeconds]`

Where <logfile> is the absolute location of nginx log file; [timeLImitInSeconds] is optional with a default value of 3 seconds

For example: 
`./nana.sh /var/log/nginx/main.log`

And here is an exmample output: 

`---------nginx summary---------  
requests: total 78970, slow 178, peak 350/s  
unique ip: total 4229, slow 53  
time: average 0.205734s, max 73.528s  
traffic: total 1158.1MB, max 1417.18KB, average 72.9927KB/req  
rate: average 4186.4KB/s, max 757.32KB/s, min 0KB/s  

---------Peak moments---------  
...  
---------Hot urls---------  
...  
---------slow summary---------  
58.244.**.** - - [22/Mar/2016:14:43:17 +0800] "GET /url HTTP/1.1" 200 28 5.801 5.801 "http://host/url1" "Mozilla/5.0 (iPhone; CPU iPhone OS 9_2_1 like Mac OS X) AppleWebKit/601.1.46 (KHTML, like Gecko) Mobile/13D15" "-"  
...  
`

# FAQ

#### How to identify requests that are really slow?
In general there are 3 types of slow requests:
1. Slow reponse from upstream servers;
2. Limited bandwith of physical servers;
3. Poor network condition of mobile phones.

From data of my site, **about 0.5% requests** are slow because of poor network condition, which should be avoided from alerting. This tool identifies a request as slow only if 8 out of 10 succedding requests are slow.

#### Print nothing?
Please check log_format of http module in your nginx configurations file(/etc/nginx/nginx.conf), which should be in the following format:

`
'$remote_addr - $remote_user [$time_local] "$request" $status $body_bytes_sent $request_time $upstream_response_time "$http_referer" "$http_user_agent" "$http_x_forwarded_for"';

// Example: 
183.63.**.** - - [21/Mar/2016:03:53:41 +0800] "GET /url HTTP/1.1" 200 100759 0.255 0.105 "-" "Mozilla/5.0 (iPhone; CPU iPhone OS 9_1 like Mac OS X) AppleWebKit/601.1.46 (KHTML, like Gecko) Mobile/13B143" "-"
`

You could use awk to check whether it works:
`
less /var/log/ngin/main.log | awk '{print $1}' | head -n 1 // should print ip addresses  
less /var/log/ngin/main.log | awk '{print $4}' | head -n 1 // should print timestamps  
less /var/log/ngin/main.log | awk '{print $7}' | head -n 1 // should print urls  
less /var/log/ngin/main.log | awk '{print $10}' | head -n 1 // should print size of reponse body  
less /var/log/ngin/main.log | awk '{print $11}' | head -n 1 // should print request time  
`
