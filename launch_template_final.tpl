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
export nginx_path=${nginx_path}
sed "s#nginx_path#${nginx_path}#g" /home/ec2-user/bookstore/bookstore/nginx.conf.tmp | sudo tee /etc/nginx/nginx.conf  #here i have changed the / delimeter to # becouse the string i want to change also has the / . 
sudo cp /home/ec2-user/bookstore/bookstore/nginx.conf.default /etc/nginx/nginx.conf.default
mkdir -p /home/ec2-user/templates/

#replace other variables 
export db_host=${db_host}
sed "s/db_host/${db_host}/g" /home/ec2-user/bookstore/bookstore/connectDB.php.tmp | tee /home/ec2-user/templates/connectDB.php.tmp2
export db_user=${db_user}
sed "s/db_user/${db_user}/g" /home/ec2-user/templates/connectDB.php.tmp2 | tee /home/ec2-user/templates/connectDB.php.tmp3
export db_pass=${db_pass}
sed "s/db_pass/${db_pass}/g" /home/ec2-user/templates/connectDB.php.tmp3 | tee /home/ec2-user/bookstore/bookstore/connectDB.php

sed "s/db_host/${db_host}/g" /home/ec2-user/bookstore/bookstore/index.php.tmp | tee /home/ec2-user/templates/index.php.tmp1
sed "s/db_user/${db_user}/g" /home/ec2-user/templates/index.php.tmp1 | tee /home/ec2-user/templates/index.php.tmp2 
sed "s/db_pass/${db_pass}/g" /home/ec2-user/templates/index.php.tmp2 | tee /home/ec2-user/bookstore/bookstore/index.php

#create the nginx path and copy file to that
sudo mkdir -p /usr/share/nginx/bookstore
sudo cp /home/ec2-user/bookstore/bookstore/* -r /usr/share/nginx/bookstore/

sudo systemctl restart nginx