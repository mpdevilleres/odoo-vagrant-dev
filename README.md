# Vagrant configuration for Odoo 10 module development #

Provides structure for developing odoo modules with community and/or enterprise source
https://github.com/odoo

## Specifications ##
- Ubuntu 16 "Xenial"
- Postgresql 9.6
- MailCatcher
- Python 2.7
- [Odoo Community Addons](https://github.com/OCA) (Web, Server Tools)

## Requirements ##
- [Vagrant](https://www.vagrantup.com/downloads.html)
- [VirtualBox](https://www.virtualbox.org/wiki/Downloads)

## Setup Development ##
Step 1: run vagrant (it may take few minutes)

    $ vagrant up

Step 2: ssh vagrant

    $ vagrant ssh

Step 3: open web browser

    http://localhost:8069

## Credentials ##
1. Postgresql
    - User: odoo
    - Password: odoo

## Running Odoo ##

    $ /vagrant/odoo/odoo-bin -c /vagrant/conf/odoo.conf

## Creating your first Module ##
    
    $ /vagrant/odoo/odoo-bin scaffold module_name /vagrant/_extra_addons

## Using Enterprise Edition ##
Provided your github account is allowed to access the enterprise repo.

Edit 'install_enterprise.sh' and fill your credentials
    
    GITHUB_USER='<fill in your username>'
    GITHUB_PASS='<fill your password>'

then run.

    bash /vagrant/install_enterprise.sh
    
Special Thanks: <br/>
https://github.com/JamesGreenAU/OdooVagrant <br/>
https://github.com/Yenthe666/InstallScript