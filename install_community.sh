#!/usr/bin/env bash
#--------------------------------------------------
# Update Server
#--------------------------------------------------
echo -e "\n---- Update Server ----"
sudo apt-get update
sudo apt-get upgrade -y

#echo -e "\n---- Update Server ----"
sudo apt-get install -y locales
sudo locale-gen en_US.UTF-8
sudo /usr/sbin/update-locale LANG=en_US.UTF-8

echo 'LC_ALL=en_US.UTF-8' >> /etc/environment


#--------------------------------------------------
# Install PostgreSQL
#--------------------------------------------------
sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt/ `lsb_release -cs`-pgdg main" >> /etc/apt/sources.list.d/pgdg.list'
sudo wget -q https://www.postgresql.org/media/keys/ACCC4CF8.asc -O - | sudo apt-key add -
sudo apt-get update

sudo apt-get install -y postgresql-9.6
sudo -u postgres psql -c "CREATE USER odoo WITH CREATEDB NOCREATEROLE PASSWORD 'odoo';"

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
sudo apt-get install -y wget git python python-dev \
                        gdebi-core libpq-dev build-essential libssl-dev libffi-dev \
                        libxml2-dev libxslt1-dev libjpeg-dev libsasl2-dev libldap2-dev

# install PIP
sudo curl https://bootstrap.pypa.io/get-pip.py | sudo python


#--------------------------------------------------
# Install Odoo Community Edition
#--------------------------------------------------

if [ -d "/vagrant/odoo" ]; then
    echo -e "\n---- Odoo Source Exist ----"
else
    echo -e "\n---- Clone Odoo Community Edition ----"
    sudo git clone --depth 1 --single-branch --branch 10.0 https://github.com/odoo/odoo.git /vagrant/odoo
fi

echo -e "\n---- PIP Install Requirements Odoo ----"
sudo pip install -r /vagrant/odoo/requirements.txt

# wkhtmltopdf
echo -e "\n---- Install other required packages ----"
sudo wget http://download.gna.org/wkhtmltopdf/0.12/0.12.2.1/wkhtmltox-0.12.2.1_linux-trusty-amd64.deb
sudo gdebi --n wkhtmltox-0.12.2.1_linux-trusty-amd64.deb

sudo cp /usr/local/bin/wkhtmltopdf /usr/bin
sudo cp /usr/local/bin/wkhtmltoimage /usr/bin

# LESS
sudo apt-get install -y python-software-properties
curl -sL https://deb.nodesource.com/setup_7.x | sudo -E bash -
sudo apt-get install -y nodejs
sudo npm install -g less less-plugin-clean-css

#--------------------------------------------------
# Create Log Directory
#--------------------------------------------------
if [ -d "/vagrant/logs" ]; then
    echo -e "\n---- Log Folder Exist ----"
else
    echo -e "\n---- Create Log Folder ----"
    sudo mkdir -p /vagrant/logs
fi

#--------------------------------------------------
# Create Addon Directory
#--------------------------------------------------
if [ -d "/vagrant/extra_addons" ]; then
    echo -e "\n---- Addon Folder Exist ----"
else
    echo -e "\n---- Create Addon Folder ----"
    sudo mkdir -p /vagrant/extra_addons
fi

#--------------------------------------------------
# Create Data Directory
#--------------------------------------------------
if [ -d "/vagrant/data" ]; then
    echo -e "\n---- Data Folder Exist ----"
else
    echo -e "\n---- Create Data Folder ----"
    sudo mkdir -p /vagrant/data
fi

#--------------------------------------------------
# Install Mail Catcher
#--------------------------------------------------
echo -e "\n---- Install Mail Catcher ----"
sudo apt-get install -y libsqlite3-dev ruby ruby-dev
sudo gem install mailcatcher

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

echo -e "\n---- DONE ----"

#--------------------------------------------------
# Cleanup
#--------------------------------------------------
echo -e "\n---- Cleaning Up ----"
sudo apt-get -y autoremove


#--------------------------------------------------
# Install custom dependencies and configuration
#--------------------------------------------------
echo -e "\n---- Install custom dependencies ----"
# sudo pip install openpyxl==2.3.5
echo -e "\n---- DONE ----"
