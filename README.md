# Vagrant configuration for Odoo 10 module development #

Provides structure for developing odoo modules with community and/or enterprise source
https://github.com/odoo

## Specifications ##
- Ubuntu 14 "Trusty"
- Postgresql 9.6
- MailCatcher
- Python 2.7

## Setup Development ##
Make sure you have Vagrant in your machine (visit https://www.vagrantup.com/)

Step 1: run vagrant (it may take few minutes)
`$ vagrant up`

Step 2: ssh vagrant
`$ vagrant ssh`

Step 3: open web browser
http://localhost:8069

## Configuring security ##
There are two default passwords supplied in this repo that you should update before using this for your own work.

1. Update the sql/authentication.sql file to set a new PostgreSQL user name and password.

2. Update the conf/odoo.conf file to reflect the new PostgreSQL password.  Also update the Odoo Database Master Password which is set in this file.

## Running Odoo ##
`$ python /vagrant/odoo/odoo-bin -c /vagrant/conf/odoo.conf`
or 
`$ python /vagrant/odoo/odoo-bin -c /vagrant/conf/odoo.conf -d test_db`

## Creating your first Module ##
`$ python /vagrant/odoo/odoo-bin scaffold module_name /vagrant/odoo_modules`

Special Thanks:
https://github.com/JamesGreenAU/OdooVagrant
https://github.com/Yenthe666/InstallScript