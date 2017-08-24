#!/usr/bin/env bash
IS_DEVELOPMENT="true"
if [[ ${IS_DEVELOPMENT} == "true" ]]; then
    SERVER_DIR="/vagrant"
else
    SERVER_DIR="${HOME}/server"
fi

GITHUB_USER='<fill in your username>'
GITHUB_PASS='<fill your password>'

ENTERPRISE_DIR="${SERVER_DIR}/_enterprise_addons"

#--------------------------------------------------
# Install Enterprise
#--------------------------------------------------
echo -e "\n---- Pull Enterprise Source ----"
sudo git clone --depth 1 --single-branch --branch 10.0 https://${GITHUB_USER}:${GITHUB_PASS}@github.com/odoo/enterprise.git ${ENTERPRISE_DIR}
echo -e "\n---- Add Enterprise modules to odoo.conf ----"

sudo sed -i 's#/vagrant/odoo/addons#/vagrant/_enterprise_addons,/vagrant/odoo/addons#g' /vagrant/conf/odoo.conf
