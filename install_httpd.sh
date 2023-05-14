#! /bin/bash
sudo yum update
sudo yum install -y httpd

cd /tmp
wget https://www.free-css.com/assets/files/free-css-templates/download/page289/zon.zip
unzip zon.zip
cp -rf zon-html/* /var/www/html/

sudo systemctl restart httpd
sudo systemctl enable httpd