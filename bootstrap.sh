#!/usr/bin/env bash
#--------------------------------------------------
# Update Server
#--------------------------------------------------
echo -e "\n---- Update Server ----"
sudo apt-get update
sudo apt-get upgrade -y
sudo apt-get install -y locales

#--------------------------------------------------
# Install PostgreSQL Server
#--------------------------------------------------
# Configure locale to utf-8
echo -e "\n---- Install PostgreSQL Server ----"
sudo dpkg-reconfigure locales
sudo locale-gen C.UTF-8
sudo /usr/sbin/update-locale LANG=C.UTF-8

echo 'LC_ALL=C.UTF-8' >> /etc/environment

sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt/ `lsb_release -cs`-pgdg main" >> /etc/apt/sources.list.d/pgdg.list'
sudo wget -q https://www.postgresql.org/media/keys/ACCC4CF8.asc -O - | sudo apt-key add -
sudo apt-get update

sudo apt-get install -y postgresql-9.6
sudo -u postgres psql -f /vagrant/sql/authentication.sql

# allow db access from the forwarded host port
echo "host    all             all             10.0.2.2/32             md5" >> /etc/postgresql/9.6/main/pg_hba.conf
sudo -u postgres pg_ctlcluster 9.6 main reload

sudo -u postgres echo "listen_addresses = '*'" >> /etc/postgresql/9.6/main/postgresql.conf
sudo -u postgres echo "max_locks_per_transaction = 200" >> /etc/postgresql/9.6/main/postgresql.conf
sudo service postgresql restart

#--------------------------------------------------
# Install Tool Packages
#--------------------------------------------------
echo -e "\n---- Install tool packages ----"
sudo apt-get install  -y wget git python-pip python-setuptools python-dev gdebi-core
#--------------------------------------------------
# Install Basic Odoo Dependencies
#--------------------------------------------------

echo -e "\n---- Install Basic Odoo Dependencies ----"
sudo apt-get install -y python-dateutil python-feedparser python-ldap python-libxslt1 python-lxml \
                        python-mako python-openid python-psycopg2 python-pybabel python-pychart \
                        python-pydot python-pyparsing python-reportlab python-simplejson python-tz \
                        python-vatnumber python-vobject python-webdav python-werkzeug python-xlwt python-yaml \
                        python-zsi python-docutils python-psutil python-mock python-unittest2 \
                        python-jinja2 python-pypdf python-decorator python-requests \
                        python-passlib python-pil -y python-suds

echo -e "\n---- Install other required packages ----"
sudo apt-get install node-clean-css node-less -y

sudo wget http://download.gna.org/wkhtmltopdf/0.12/0.12.2.1/wkhtmltox-0.12.2.1_linux-trusty-amd64.deb
sudo gdebi --n wkhtmltox-0.12.2.1_linux-trusty-amd64.deb

# Symlink
sudo ln -s /usr/local/bin/wkhtmltopdf /usr/bin
sudo ln -s /usr/local/bin/wkhtmltoimage /usr/bin

#--------------------------------------------------
# Clone Odoo Source
#--------------------------------------------------
if [ -d "/vagrant/odoo" ]; then
    echo -e "\n---- Odoo Source Exist ----"
else
    echo -e "\n---- Clone Odoo Source ----"
    sudo git clone --depth 1 --single-branch --branch 10.0 https://github.com/odoo/odoo.git /vagrant/odoo
fi
# Install Requirements
sudo pip install -y /vagrant/odoo/requirements.txt

# Additional Helpful Python Modules
sudo pip install ipdb ipython openpyxl==2.3.5

#--------------------------------------------------
# Install Mail Catcher
#--------------------------------------------------
echo -e "\n---- Install Mail Catcher ----"
sudo apt-get install -y libsqlite3-dev ruby2.0 ruby2.0-dev
sudo gem2.0 install mailcatcher

#--------------------------------------------------
# Create Startup Script for Mail Catcher
# Use SMTP PORT 25 as Odoo uses it by default
#--------------------------------------------------
echo -e "\n---- Create Startup for Mail Catcher ----"
cat <<EOT > /etc/init/mailcatcher.conf
description "Mailcatcher"

start on runlevel [2345]
stop on runlevel [!2345]

respawn

exec /usr/bin/env $(which mailcatcher) --foreground --http-ip=0.0.0.0 --smtp-port=25
EOT

sudo service mailcatcher status
sudo service mailcatcher start

#
# Clean up
#
sudo apt-get -y autoremove

echo -e "\n---- DONE ----"