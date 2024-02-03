#!/bin/bash
sudo echo "db_host=${db_host}" | sudo tee /etc/profile
sudo echo "db_user=${db_user}" | sudo tee /etc/profile
sudo echo "db_pass=${db_pass}" | sudo tee /etc/profile
sudo echo "nginx_path=${nginx_path}" | sudo tee /etc/profile