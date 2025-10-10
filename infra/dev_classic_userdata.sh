#!/bin/bash
# dev_classicuserdata script
# This script will be used as user-data for both public dev_classicand private EC2 (adjust as needed)

set -e
exec > /var/log/dev_classic-userdata.log 2>&1

echo "Starting userdata at $(date)"

# update & base packages
apt-get update -y
apt-get install -y software-properties-common git vim curl

# install ansible (optional — only if you need it)
add-apt-repository --yes --update ppa:ansible/ansible
apt-get update -y
apt-get install -y ansible || true

# Example: clone your repo (idempotent)
if [ ! -d /opt/ansible-playbooks ]; then
  git clone https://github.com/thani2808/first-bastion.git /opt/ansible-playbooks || true
else
  cd /opt/ansible-playbooks && git pull || true
fi

# Any other bootstrap steps
echo "dev_classicuserdata completed at $(date)"