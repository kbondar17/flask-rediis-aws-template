#!/bin/bash
yum update -y  
yum install docker -y
service docker start
usermod -a -G docker ec2-user
yum install git -y
echo export REDIS_HOST="10.0.1.189" >> /etc/profile
docker run -p 8080:8080 -e REDIS_HOST=$REDIS_HOST kbondar17/flask-redis