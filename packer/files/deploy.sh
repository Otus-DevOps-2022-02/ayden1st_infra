#!/bin/bash

apt-get install -y git
cd /opt
git clone -b monolith https://github.com/express42/reddit.git
addgroup --system puma
adduser --system --home /opt/reddit --shell /bin/nologin --ingroup puma --no-create-home puma
cd reddit
bundle install
chown -R puma:puma reddit
cp /tmp/puma.service /etc/systemd/system/
systemctl daemon-reload
systemctl enable --now puma.service
