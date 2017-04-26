#!/usr/bin/env bash

GITHUB_USER='<fill in your username>'
GITHUB_PASS='<fill your password>'

#--------------------------------------------------
# Install Enterprise
#--------------------------------------------------
echo -e "\n---- Pull Enterprise Source ----"
sudo git clone --depth 1 --single-branch --branch 10.0 https://${GITHUB_USER}:${GITHUB_PASS}@github.com/odoo/enterprise.git /vagrant/enterprise_addons
echo -e "\n---- Add Enterprise modules to odoo.conf ----"
sudo sed -i 's#/vagrant/odoo/addons#/vagrant/enterprise_addons,/vagrant/odoo/addons#g' /vagrant/conf/odoo.conf
