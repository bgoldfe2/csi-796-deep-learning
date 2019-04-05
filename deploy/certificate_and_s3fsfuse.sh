#!/bin/bash
set -x -e

cd /home/ec2-user/
mkdir certs
cd certs
sudo openssl req -x509 -nodes -days 10 -newkey rsa:1024 -keyout "cert.key" -out "cert.pem" -batch

yum install -y automake fuse fuse-devel libxml2-devel
cd /mnt

git clone https://github.com/s3fs-fuse/s3fs-fuse.git
cd s3fs-fuse/
./autogen.sh
./configure
make
make install

echo user_allow_other >> /etc/fuse.conf
/usr/local/bin/s3fs -o allow_other -o iam_role=auto  -o url=https://s3.amazonaws.com  -o no_check_certificate  YourBucket /mnt/jupyter-notebooks
