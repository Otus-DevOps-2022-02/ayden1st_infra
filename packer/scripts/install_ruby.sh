#!/bin/bash

echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections
apt-get update -y
sleep 30
apt-get install -y ruby-full ruby-bundler build-essential
