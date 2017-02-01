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
sudo apt-get install  -y wget git python-pip python-setuptools \
                         python-dev gdebi-core libpq-dev build-essential libssl-dev libffi-dev \
                         libxml2-dev libxslt1-dev libjpeg-dev libsasl2-dev libldap2-dev

#--------------------------------------------------
# Install Basic Odoo
#--------------------------------------------------

if [ -d "/vagrant/odoo" ]; then
    echo -e "\n---- Odoo Source Exist ----"
else
    echo -e "\n---- Clone Odoo Source ----"
    sudo git clone --depth 1 --single-branch --branch 10.0 https://github.com/odoo/odoo.git /vagrant/odoo
fi

echo -e "\n---- Install PIP Requirements Odoo ----"
sudo pip install -r /vagrant/odoo/requirements.txt

# Additional Helpful Python Modules
#sudo pip install ipdb ipython
sudo pip install ipdb ipython[notebook] openpyxl==2.3.5 pandas

# Add odoo path to python
echo export PYTHONPATH="${PYTHONPATH}:/vagrant/odoo" >> ~/.bashrc

echo -e "\n---- Install other required packages ----"
sudo apt-get install node-clean-css node-less -y

sudo wget http://download.gna.org/wkhtmltopdf/0.12/0.12.2.1/wkhtmltox-0.12.2.1_linux-trusty-amd64.deb
sudo gdebi --n wkhtmltox-0.12.2.1_linux-trusty-amd64.deb

# Symlink
sudo ln -s /usr/local/bin/wkhtmltopdf /usr/bin
sudo ln -s /usr/local/bin/wkhtmltoimage /usr/bin

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

#--------------------------------------------------
# Create Startup Script for Jupyter
#--------------------------------------------------
echo -e "\n---- Create Startup for Jupyter ----"
cat <<EOT > /etc/init/jupyter.conf
description "jupyter"

start on runlevel [2345]
stop on runlevel [!2345]

respawn

exec /usr/bin/env $(which jupyter) notebook --no-browser --port=8888 --ip=0.0.0.0 --notebook-dir=/vagrant

EOT

sudo service jupyter status
sudo service jupyter start

#--------------------------------------------------
# Clean up
#--------------------------------------------------
sudo apt-get -y autoremove
echo -e "\n---- DONE ----"