#!/usr/bin/env bash
#--------------------------------------------------
# Update Server
#--------------------------------------------------
IS_DEVELOPMENT="true"
if [[ ${IS_DEVELOPMENT} == "true" ]]; then
    SERVER_DIR="/vagrant"
else
    SERVER_DIR="${HOME}/odoo-server"
fi

EXTRA_DIR="${SERVER_DIR}/_extra_addons_11"
OCA_DIR="${SERVER_DIR}/_oca_addons_11"
SYSTEMD_SERVICES_DIR="${SERVER_DIR}/system_services"

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

if [[ ${IS_DEVELOPMENT} == "true" ]]; then
    sudo echo "host    all             all             0.0.0.0/0            md5" | sudo tee -a /etc/postgresql/9.6/main/pg_hba.conf
    sudo -u postgres pg_ctlcluster 9.6 main reload

    sudo echo "listen_addresses = '*'" | sudo tee -a /etc/postgresql/9.6/main/postgresql.conf
    sudo echo "max_locks_per_transaction = 200" | sudo tee -a /etc/postgresql/9.6/main/postgresql.conf
    sudo systemctl restart postgresql
fi

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
    sudo git clone --depth 1 --single-branch --branch 11.0 https://github.com/odoo/odoo.git ${SERVER_DIR}/odoo11
fi

echo -e "\n---- PIP Install Requirements Odoo ----"
sudo -H pip3.6 install -r ${SERVER_DIR}/odoo11/requirements.txt

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
# Create Log Directory
#--------------------------------------------------
if [ -d "${SERVER_DIR}/logs" ]; then
    echo -e "\n---- Log Folder Exist ----"
else
    echo -e "\n---- Create Log Folder ----"
    sudo mkdir -p ${SERVER_DIR}/logs
fi

#--------------------------------------------------
# Create Addon Directory
#--------------------------------------------------
if [ -d "${EXTRA_DIR}" ]; then
    echo -e "\n---- Addon Folder Exist ----"
else
    echo -e "\n---- Create Addon Folder ----"
    sudo mkdir -p ${EXTRA_DIR}
fi

#--------------------------------------------------
# Configure Config File
#--------------------------------------------------
echo -e "\n---- Configure Config File ----"
sudo cp ${SERVER_DIR}/conf/odoo.conf.template ${SERVER_DIR}/conf/odoo.conf
sudo sed -i -e "s|__SERVER_DIR__|${SERVER_DIR}|g" ${SERVER_DIR}/conf/odoo.conf

#--------------------------------------------------
# Install CUPS
#--------------------------------------------------
# sudo apt-get install cups

#--------------------------------------------------
# Install Mail Catcher
#--------------------------------------------------
echo -e "\n---- Install Mail Catcher ----"
sudo apt-get install -y libsqlite3-dev ruby ruby-dev
sudo gem install mailcatcher

#--------------------------------------------------
# Add Systemd Startup
#--------------------------------------------------
echo -e "\n---- Injecting mailcatcher.service ----"
sudo cp ${SYSTEMD_SERVICES_DIR}/mailcatcher.service /etc/systemd/system/

if [[ ${IS_DEVELOPMENT} == "false" ]]; then
    echo -e "\n---- Injecting odoo.service ----"
    sudo cp ${SYSTEMD_SERVICES_DIR}/odoo.service /etc/systemd/system/
    sudo sed -i -e "s|__SERVER_DIR__|${SERVER_DIR}|g" /etc/systemd/system/odoo.service
fi

echo -e "\n---- Reload Services ----"
sudo systemctl daemon-reload

echo -e "\n---- Enable mailcatcher.service ----"
    sudo chmod 755 /etc/systemd/system/mailcatcher.service
    sudo chown root: /etc/systemd/system/mailcatcher.service
sudo systemctl enable mailcatcher.service

if [[ ${IS_DEVELOPMENT} == "false" ]]; then
    echo -e "\n---- Enable odoo.service ----"
    sudo chmod 755 /etc/systemd/system/odoo.service
    sudo chown root: /etc/systemd/system/odoo.service
    sudo systemctl enable odoo.service
fi


#--------------------------------------------------
# Install custom dependencies and configuration
#--------------------------------------------------
echo -e "\n---- Install custom dependencies ----"
