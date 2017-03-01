# Production use - Proxying eXist-db behind a Web Server

## Abstract

> From a security perspective, it is recognised best practice to proxy Web Application Servers behind dedicated Web Servers, and eXist-db is no exception.
>
> Some other nice side-effects of proxying eXist-db behind a Web Server include -
>
> Unified web namespace  
> You can map eXist-db or an application build atop eXist-db into an existing web namespace. If your website is - http://www.mywebsite.com, then your eXist-db application could be mapped into http://www.mywebsite.com/myapplication/.
>
> Virtual Hosting  
> Providing your Web Server supports Virtual Hosting, then you should be able to proxy many URLs from different domains onto different eXist-db REST URLs which may belong to one or more eXist-db instances. This in effect allows a single eXist-db instance to perform virtual hosting.
>
> Examples are provided for -
>
> [Nginx](http://wiki.nginx.org/Main)  
> A very small but extremely poweful Web Server which is also very simple to configure. It powers some of the biggest sites on the Web.
>
> [Apache HTTPD](http://httpd.apache.org/)  
> The most prolific Web Server used on the web.

## Example 1 - Proxying a Web Domain Name to an eXist-db Collection

In this example we look at how to proxy a web domain name onto an eXist-db Collection. We make the following assumptions -

1.  http://www.mywebsite.com is our website domain name address
2.  eXist-db is running in standalone mode (i.e. http://localhost:8088/) on the same host as the Web Server (i.e. http://localhost:80/)
3.  /db/apps/mywebsite.com is the eXist-db collection we want to proxy
4.  Web Server access logging will be written to /srv/www/vhosts/mywebsite.com/logs/access.log

### Nginx

This needs to be added to the http section of the nginx.conf file -

``` nginx
# header helpers for reverse proxied servers
proxy_set_header        Host                    $host;                          # Ensures the actual hostname is sent to eXist-db and not 'localhost' (needed in eXist-db for server-name in controller-config.xml)
proxy_set_header        X-Real-IP               $remote_addr;                   # The Real IP of the client and not the IP of nginx proxy
proxy_set_header        X-Forwarded-For         $proxy_add_x_forwarded_for;
proxy_set_header        nginx-request-uri       $request_uri;                   # The original URI before proxying

# virtual host configuration, reverse proxy to eXist-db
server {
    listen 80;
    server_name *.mywebsite.com;
    charset utf-8;
    access_log /srv/www/vhosts/mywebsite.com/logs/access.log;

    location / {
        proxy_pass http://localhost:8088/exist/apps/mywebsite.com/;
    }
}
                
```

### Apache HTTPD

This needs to be added to your httpd.conf -

``` xml
<VirtualHost *:80>
    ProxyRequests       off
    ServerName      www.mywebsite.com
    ServerAlias     *.mywebsite.com
    ProxyPass       /   http://localhost:8088/exist/apps/mywebsite.com
    ProxyPassReverse    /   http://localhost:8088/exist/apps/mywebsite.com
    ProxyPassReverseCookieDomain localhost mywebsite.com
    ProxyPassReverseCookiePath /exist /

    RewriteEngine       on
    RewriteRule         ^/(.*)$     /$1   [PT]
</VirtualHost>
          
```
