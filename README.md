This page is intended to provide quick reference guide for creating tracking beackon that can be inserted into MS Office documents. The aim of the exercise is to capture timestamp/IP and unique ID without need for macro in document during phishing exercise. The resulting infrastructure & beacon should help to measure if it’s possible to get through email filters & corporate proxy and if document was successfully opened without deplooying any payloads.

File an issue on the repo/or submit pull request if you would like to add anything.

# Table of Contents

- [Host Design](#host-design)
- [Beacon Design](#beacon-design)
- [Socat](#socat)
- [Beacon Output](#beacon-output)
- [Notes](#notes)


# Host Design

See [build.sh](server/build.sh) for source on how the box is created. The script needs to be edited beforehand to ensure that appropriate IPs are added in ALLOW_IP variable. Its not clever but sets up the box as needed. Script was tested on Debian 9 x64.

The script will perform the following actions:

* Change SSH port from 22/tcp to 50055/tcp
* Install apache + php 
* Crate folder structure in /var/www/html
* Add tracking script as index.php
* Add .htaccess file hinding .php extension + add error handling
* Configured IPTABLES to allow only specific IPs to access SSH but leaves 443/80 ports open for the world. As defined by ALLOW_IP variable.
* Change Apache config to enable mod_rewrite
* Disable IPv6
* Disable NTP service

After configuration all requests will be stored in /var/www/html/cookies/ folder (easily changable in source code) however. By default this folder is denied to the world.

# Beacon Design

Beacon design is equally simple. All we are doing is inserting tracking URL that points to tracking server /index?id=XXXXXX location (replace XXXXXX with any value). Adding tracking image to document header/footer and covering it with white overlay seems to work quite nice.

The steps below show how to add working beacon to Word document.

**Open up document**

![Alt text](beacon/start.png?raw=true "Step1")

**Open Quick Parts > Field**

![Alt text](beacon/step1.png?raw=true "Step2")

**Scroll down to IncludePicture field and insert URL to server. Tick "Data not stored with document"**

![Alt text](beacon/step2.png?raw=true "Step3")

**Finally remove any uncessary data from the document**

![Alt text](beacon/step3.png?raw=true "Step4")
![Alt text](beacon/step4.png?raw=true "Step5")
![Alt text](beacon/step5.png?raw=true "Step6")

**And cover inserted URL field with white rectangle (remember to remove borders etc)**

![Alt text](beacon/step6-custom.png?raw=true "Step7")


# Socat 

Sometimes its necessary to use socat for redirections if there is external box in front of the tracker. This can be easily achieved using following commands:

```
socat TCP4-LISTEN:80,fork TCP4:<DESTINATION>:<DESTINATION PORT>
```

# Beacon output 

The following sample was produced by the beacon tracking script and stored in /var/www/html/cookies/. Its basically timestamp + path + browser version + cookie value (if any added).  
```
[11/03/2018 21:04:36] x.x.x.x     /index.php      Mozilla/5.0 (Windows NT 6.3; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/65.0.3325.146 Safari/537.36      123

[11/03/2018 21:07:47] x.x.x.x     /index.php      Mozilla/5.0 (Windows NT 6.3; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/65.0.3325.146 Safari/537.36      NO_COOKIE

[11/03/2018 21:07:52] x.x.x.x     /index.php      Mozilla/5.0 (Windows NT 6.3; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/65.0.3325.146 Safari/537.36      1123

[11/03/2018 21:08:52] x.x.x.x     /index.php      Mozilla/5.0 (Windows NT 6.3; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/65.0.3325.146 Safari/537.36      123

[11/03/2018 21:18:12] x.x.x.x     /index.php      Mozilla/5.0 (Windows NT 6.3; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/65.0.3325.146 Safari/537.36      123
```

# Notes

* Beacon doesn't work unless "Enable Content" warning in Office is dismissed. By default "field" in document is not active when the origin of the document is from either network share or 'Internet'. Office will instead open "Protected View".
* Don't forget to change index.html to something sensible and do not leave it as start page for apache.
* HTTPS setup can be done separetly and IPTABLES are opened for this reason. Close them if you don't want/need HTTPS.
* This setup have been tested on Debian 9.3 x64 so should work on Debian in general. 
