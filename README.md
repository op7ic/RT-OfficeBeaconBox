This page is intended to provide a resource for setting really quick office beacon & tracking box that can be used to identify if somebody opened a Office document submitted during initial phishing exercise. The aim is to capture timestamp/IP and unique ID without creating massive noise or need for macro documents. The resulting infrastructure & beacon should help to measure if it’s possible to get through email filters quickly without much fuzz.

File an issue on the repo/or submit pull request if you would like to add anything.

# Table of Contents

- [Host Design](#host-design)
- [Beacon Design](#beacon-design)
- [Socat](#socat)
- [Domains](#domain)

# Host Design

See [server/build.sh] for source. The script needs to be edited beforehand to ensure that appropriate IPs are added in ALLOW_IP variable. Yes its not clever but sets up the box as needed.

The script performs the following actions:

* Change SSH port from 22/tcp to 50055/tcp
* Install apache + php 
* Crate folder structure in /var/www/html
* Add tracking script as index.php
* Add .htaccess file hinding .php extension
* Configured IPTABLES to allow only specific IPs to access SSH but leaves 443/80 ports open for the world. As defined by ALLOW_IP variable.

# Beacon Design

Beacon design is equally simple. All we are doing is inserting tracking URL as noted below that points to tracking server.

The steps below show how to add working beacon to word document.

![Alt text](beacon/start.png?raw=true "Step1")
![Alt text](beacon/step1.png?raw=true "Step2")
![Alt text](beacon/step2.png?raw=true "Step3")
![Alt text](beacon/step3.png?raw=true "Step4")
![Alt text](beacon/step4.png?raw=true "Step5")
![Alt text](beacon/step5.png?raw=true "Step6")
![Alt text](beacon/step6-custom.png?raw=true "Step7")



#Socat 
Sometimes its necessary to use socat for redirections. This can be easily achieved using following commands:

##Socat for HTTP

HTTP traffic can be easily handed using socat as 'proxy' between 
```
socat TCP4-LISTEN:80,fork TCP4:<DESTINATION>:<DESTINATION PORT>
```

# Notes

* Beacon doesn't work unless "enabled content" warning is dismissed. By default any fields in document from either network share or 'Internet' are blocked.
