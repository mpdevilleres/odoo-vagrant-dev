#!/usr/bin/env bash
#--------------------------------------------------
# Update Server
#--------------------------------------------------
IS_DEVELOPMENT="true"
if [[ ${IS_DEVELOPMENT} == "true" ]]; then
    SERVER_DIR="/vagrant"
else
    SERVER_DIR="${HOME}/server"
fi

EXTRA_DIR="${SERVER_DIR}/_extra_addons"
OCA_DIR="${SERVER_DIR}/_oca_addons"
SYSTEMD_SERVICES_DIR="${SERVER_DIR}/system_services"

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
# Install Tool Packages
#--------------------------------------------------
echo -e "\n---- Install tool packages ----"
sudo apt-get install -y wget git python python-dev \
                        gdebi-core libpq-dev build-essential libssl-dev libffi-dev \
                        libxml2-dev libxslt1-dev libjpeg-dev libsasl2-dev libldap2-dev

# install PIP
sudo curl https://bootstrap.pypa.io/get-pip.py | sudo python


#--------------------------------------------------
# Install Basic Odoo
#--------------------------------------------------

if [ -d "${SERVER_DIR}/odoo" ]; then
    echo -e "\n---- Odoo Source Exist ----"
else
    echo -e "\n---- Clone Odoo Source ----"
    sudo git clone --depth 1 --single-branch --branch 10.0 https://github.com/odoo/odoo.git ${SERVER_DIR}/odoo
fi

echo -e "\n---- PIP Install Requirements Odoo ----"
sudo -H pip install -r ${SERVER_DIR}/odoo/requirements.txt

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
# Download OCA modules
#--------------------------------------------------
if [ -d "${OCA_DIR}" ]; then
    echo -e "\n---- OCA Addons Exist ----"
else
    echo -e "\n---- Create oca_addons ----"
    sudo mkdir -p ${OCA_DIR}
    echo -e "\n---- Clone Web Source ----"
    sudo git clone --depth 1 --single-branch --branch 10.0 https://github.com/OCA/web.git ${OCA_DIR}/web
    echo -e "\n---- Clone Server Tools Source ----"
    sudo git clone --depth 1 --single-branch --branch 10.0 https://github.com/OCA/server-tools.git ${OCA_DIR}/server_tools
    echo -e "\n---- Install Server Tools Requirements ----"
    sudo -H pip install -r ${OCA_DIR}/server_tools/requirements.txt
fi


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
# Create Config Directory
#--------------------------------------------------
if [ -d "${SERVER_DIR}/config" ]; then
    echo -e "\n---- Config Folder Exist ----"
else
    echo -e "\n---- Create Config Folder ----"
    sudo mkdir -p ${SERVER_DIR}/config
fi

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
for f in ${SYSTEMD_SERVICES_DIR}/*.service; do
    filename=$(basename ${f})
    echo -e "\n---- Injecting ${filename} ----"
    sudo cp ${SYSTEMD_SERVICES_DIR}/${filename} /lib/systemd/system/
done

echo -e "\n---- Reload Services ----"
sudo systemctl daemon-reload

for f in ${SYSTEMD_SERVICES_DIR}/*.service; do
    filename=$(basename ${f})
    echo -e "\n---- Enable ${filename} ----"
    sudo systemctl enable ${f}
done

#--------------------------------------------------
# Install custom dependencies and configuration
#--------------------------------------------------
echo -e "\n---- Install custom dependencies ----"


echo -e "\n---- config git ----"
#sudo git config --global user.name ""
#sudo git config --global user.email ""
