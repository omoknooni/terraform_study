#!/bin/bash
echo "[*] Install Nginx"
apt update
apt upgrade -y
apt install -y nginx
systemctl enable nginx
systemctl restart nginx