#!/bin/bash
# sudo chmod +x /home/ec2-user/exports.sh
# sudo sh /home/ec2-user/exports.sh
sudo yum install nginx -y
sudo yum install php8.1.x86_64 php8.1-gd.x86_64 php8.1-soap.x86_64 php8.1-intl.x86_64 php8.1-mysqlnd.x86_64 php8.1-pdo.x86_64 php8.1-fpm.x86_64 php8.1-odbc.x86_64 php8.1-common.x86_64 php8.1-xml.x86_64 -y
sudo yum install git -y
sudo yum install gettext -y
cd /home/ec2-user/
git clone https://github.com/sumzzgit/bookstore.git 
#install mysql
sudo wget https://dev.mysql.com/get/mysql80-community-release-el9-1.noarch.rpm 
sudo dnf install mysql80-community-release-el9-1.noarch.rpm -y
sudo dnf install mysql-community-server -y
sudo systemctl start mysqld

#import the database to rds
cd /home/ec2-user/bookstore/bookstore/
mysql -u ${db_user} -h ${db_host} -p${db_pass} < /home/ec2-user/bookstore/bookstore/database.sql

#replcae variables in nginx.conf
sudo nginx_path=${nginx_path} envsubst < /home/ec2-user/bookstore/bookstore/nginx.conf.tmp | sudo tee /etc/nginx/nginx.conf
sudo cp /home/ec2-user/bookstore/bookstore/nginx.conf.default /etc/nginx/nginx.conf.default
sudo mkdir -p /home/ec2-user/templates/

#replace other variables
sudo db_host=${db_host} envsubst < /home/ec2-user/bookstore/bookstore/connectDB.php.tmp | sudo tee /home/ec2-user/templates/connectDB.php.tmp2 
sudo db_user=${db_user} envsubst < /home/ec2-user/templates/connectDB.php.tmp2 | sudo tee /home/ec2-user/templates/connectDB.php.tmp3
sudo db_pass=${db_pass} envsubst < /home/ec2-user/templates/connectDB.php.tmp3 | sudo tee /home/ec2-user/bookstore/bookstore/connectDB.php

sudo db_host=${db_host} envsubst < /home/ec2-user/bookstore/bookstore/index.php.tmp | sudo tee /home/ec2-user/templates/index.php.tmp1 
sudo db_host=${db_pass} envsubst < /home/ec2-user/templates/index.php.tmp1 | sudo tee /home/ec2-user/templates/index.php.tmp2
sudo db_host=${db_user} envsubst < /home/ec2-user/templates/index.php.tmp2 | sudo tee /home/ec2-user/bookstore/bookstore/index.php

#create the nginx path and copy file to that
sudo mkdir -p /usr/share/nginx/bookstore
sudo cp /home/ec2-user/bookstore/bookstore/* -r /usr/share/nginx/bookstore/

sudo systemctl restart nginx