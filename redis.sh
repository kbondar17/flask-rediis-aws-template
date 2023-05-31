#!/bin/bash
yum update -y  
yum install docker -y
service docker start
usermod -a -G docker ec2-user
# yum install git -y
docker run -p 6379:6379 redis