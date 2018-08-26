#!/usr/bin/env bash
#--------------------------------------------------
# Variables
#--------------------------------------------------
ODOO_VERSION=11.0
SERVER_DIR="/vagrant"

EXTRA_ADDONS_DIR="${SERVER_DIR}/_extra_addons"
DATA_DIR="${SERVER_DIR}/data"

IS_ENTERPRISE="false"

# Required IF YOU WANT TO INSTALL ENTERPRISE ! ! !
#--------------------------------------------------
GITHUB_USER='<fill in your username>'
GITHUB_PASS='<fill your password>'
ENTERPRISE_DIR="${SERVER_DIR}/_enterprise_addons"


#--------------------------------------------------
# Update Server
#--------------------------------------------------
if [ -d "${SERVER_DIR}" ]; then
    echo -e "\n---- Server Directory Exist ----"
else
    echo -e "\n---- Create Server Directory ----"
    sudo mkdir -p ${SERVER_DIR}
fi

echo -e "\n---- Update Server ----"
sudo apt-get update
sudo apt-get upgrade -y

#echo -e "\n---- Update Server ----"
sudo apt-get install -y locales
sudo locale-gen en_US.UTF-8
sudo /usr/sbin/update-locale LANG=en_US.UTF-8

sudo echo "LC_ALL=en_US.UTF-8" | sudo tee -a /etc/environment

#--------------------------------------------------
# Install PostgreSQL
#--------------------------------------------------
sudo echo "deb http://apt.postgresql.org/pub/repos/apt/ `lsb_release -cs`-pgdg main" | sudo tee -a /etc/apt/sources.list.d/pgdg.list
sudo wget -q https://www.postgresql.org/media/keys/ACCC4CF8.asc -O - | sudo apt-key add -
sudo apt-get update

sudo apt-get install -y postgresql-9.6
sudo -u postgres psql -c "CREATE USER odoo WITH CREATEDB NOCREATEROLE PASSWORD 'odoo';"

sudo echo "host    all             all             0.0.0.0/0            md5" | sudo tee -a /etc/postgresql/9.6/main/pg_hba.conf
sudo -u postgres pg_ctlcluster 9.6 main reload

sudo echo "listen_addresses = '*'" | sudo tee -a /etc/postgresql/9.6/main/postgresql.conf
sudo echo "max_locks_per_transaction = 200" | sudo tee -a /etc/postgresql/9.6/main/postgresql.conf
sudo systemctl restart postgresql

#--------------------------------------------------
# Install Python 3.6.3
#--------------------------------------------------
echo -e "\n---- Install tool packages ----"
sudo apt-get install -y build-essential wget git gdebi-core \
                        libpq-dev libffi-dev libxml2-dev libxslt1-dev \
                        libreadline-gplv2-dev libncursesw5-dev libssl-dev \
                        libsqlite3-dev libgdbm-dev libc6-dev libbz2-dev \
                        zlib1g-dev libfreetype6-dev libjpeg-dev libsasl2-dev \
                        libldap2-dev libreadline-gplv2-dev libncursesw5-dev tk-dev

echo -e "\n---- Install Python 3.6.3 ----"
wget https://www.python.org/ftp/python/3.6.3/Python-3.6.3.tar.xz
tar xvf Python-3.6.3.tar.xz
cd Python-3.6.3
./configure --enable-optimizations
sudo make altinstall

cd ..
sudo rm -rf Python-3.6.3 && sudo rm Python-3.6.3.tar.xz

#--------------------------------------------------
# Install Basic Odoo
#--------------------------------------------------

if [ -d "${SERVER_DIR}/odoo11" ]; then
    echo -e "\n---- Odoo Source Exist ----"
else
    echo -e "\n---- Clone Odoo Source ----"
    sudo git clone --depth 1 --single-branch --branch ${ODOO_VERSION} https://github.com/odoo/odoo.git ${SERVER_DIR}/odoo
fi

echo -e "\n---- PIP Install Requirements Odoo ----"
sudo -H pip3.6 install -r ${SERVER_DIR}/odoo/requirements.txt

# wkhtmltopdf
echo -e "\n---- Install other required packages ----"
echo -e "\n---- Install wkhtmltopdf ----"
sudo wget https://github.com/wkhtmltopdf/wkhtmltopdf/releases/download/0.12.1/wkhtmltox-0.12.1_linux-trusty-amd64.deb
sudo gdebi --n wkhtmltox-0.12.1_linux-trusty-amd64.deb
sudo rm -rf wkhtmltox-0.12.1_linux-trusty-amd64.deb

sudo cp /usr/local/bin/wkhtmltopdf /usr/bin
sudo cp /usr/local/bin/wkhtmltoimage /usr/bin

# LESS
echo -e "\n---- Install LESS via nodejs npm ----"
sudo apt-get install -y python-software-properties
sudo curl -sL https://deb.nodesource.com/setup_7.x | sudo -E bash -
sudo apt-get install -y nodejs
sudo npm install -g less less-plugin-clean-css

#--------------------------------------------------
# Create Directories
#--------------------------------------------------
if [ -d "${SERVER_DIR}/logs" ]; then
    echo -e "\n---- Log Folder Exist ----"
else
    echo -e "\n---- Create Log Folder ----"
    sudo mkdir -p ${SERVER_DIR}/logs
fi

if [ -d "${DATA_DIR}" ]; then
    echo -e "\n---- Data Folder Exist ----"
else
    echo -e "\n---- Create Data Folder ----"
    sudo mkdir -p ${DATA_DIR}
fi

if [ -d "${EXTRA_ADDONS_DIR}" ]; then
    echo -e "\n---- Addon Folder Exist ----"
else
    echo -e "\n---- Create Addon Folder ----"
    sudo mkdir -p ${EXTRA_ADDONS_DIR}
fi

#--------------------------------------------------
# Install Mail Catcher
#--------------------------------------------------
echo -e "\n---- Install Mail Catcher ----"
sudo apt-get install -y libsqlite3-dev ruby ruby-dev
sudo gem install mailcatcher

echo -e "\n---- Injecting mailcatcher.service ----"

sudo cp ${SERVER_DIR}/system_services/mailcatcher.service /etc/systemd/system/

echo -e "\n---- Reload Services ----"
sudo systemctl daemon-reload

echo -e "\n---- Enable mailcatcher.service ----"
sudo chmod 755 /etc/systemd/system/mailcatcher.service
sudo chown root: /etc/systemd/system/mailcatcher.service
sudo systemctl enable mailcatcher.service


#--------------------------------------------------
# Install Enterprise
#--------------------------------------------------
if [[ ${IS_ENTERPRISE} == "true" ]]; then
    echo -e "\n---- Pull Enterprise Source ----"
    sudo git clone --depth 1 --single-branch --branch ${ODOO_VERSION} https://${GITHUB_USER}:${GITHUB_PASS}@github.com/odoo/enterprise.git ${ENTERPRISE_DIR}
fi

#--------------------------------------------------
# Create Config File
#--------------------------------------------------
sudo sed -i 's#/vagrant/odoo/addons#/vagrant/_enterprise_addons,/vagrant/odoo/addons#g' /vagrant/conf/odoo.conf

if [ -d "${SERVER_DIR}" ]; then
    echo -e "\n---- Server Directory Exist ----"
fi


#--------------------------------------------------
# Configure Config File
#--------------------------------------------------
echo -e "\n---- Configure Config File ----"

CONF_FILE=${SERVER_DIR}/conf/odoo.conf
ADDONS_DIR="/vagrant/odoo/addons,${EXTRA_ADDONS_DIR}"

if [[ ${IS_ENTERPRISE} == "true" ]]; then
    ADDONS_DIR="/vagrant/_enterprise_addons,${ADDONS_DIR}"

fi

sudo sed -i -e "s|addons_path =|addons_path = ${ADDONS_DIR}|g" ${CONF_FILE}
sudo sed -i -e "s|data_dir =|data_dir = ${DATA_DIR}|g" ${CONF_FILE}

echo -e "\n---- Done Preparing Your Development Environment ----"
