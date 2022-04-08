#!/bin/bash

sudo apt-get install -y git
cd /opt
sudo git clone -b monolith https://github.com/express42/reddit.git
sudo addgroup --system puma
sudo adduser --system --home /opt/reddit --shell /bin/nologin --ingroup puma --no-create-home puma
cd reddit
sudo bundle install
sudo chown -R puma:puma reddit
sudo cp /tmp/puma.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now puma.service
