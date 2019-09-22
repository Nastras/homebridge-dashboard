#!/bin/bash

echo -n "Installing homebridge-dashboard... "

DEST_I18N_FILES=/usr/local/share/homebridge-dashboard
DEST_DASHBOARD=/usr/local/bin
PWD=$(pwd)

sudo mkdir -p "$DEST_I18N_FILES"
cd /tmp
git clone https://github.com/Nastras/homebridge-dashboard.git > /dev/null 2>&1

sudo mv /tmp/homebridge-dashboard/i18n/* "$DEST_I18N_FILES"
sudo mv /tmp/homebridge-dashboard/homebridge-dashboard.sh "$DEST_DASHBOARD"
sudo rm -rf /tmp/homebridge-dashboard

sudo chmod +x "$DEST_DASHBOARD/homebridge-dashboard.sh"
cd $PWD

echo "done."
