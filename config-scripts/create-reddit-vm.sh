#!/bin/bash

yc compute instance create \
--name reddit-app \
--hostname reddit-app \
--memory=4 \
--create-boot-disk image-family=reddit-full \
--network-interface subnet-name=default-ru-central1-a,nat-ip-version=ipv4 \
--ssh-key ~/.ssh/appuser.pub
