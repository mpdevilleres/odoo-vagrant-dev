# Vagrant configuration for Odoo 11 module development #

Provides structure for developing odoo modules with community and/or enterprise source
https://github.com/odoo

## Specifications ##
- Ubuntu 16 "Xenial"
- Postgresql 9.6
- MailCatcher
- Python 3.6

## Requirements ##
- [Vagrant](https://www.vagrantup.com/downloads.html)
- [VirtualBox](https://www.virtualbox.org/wiki/Downloads)

## Using Enterprise Edition ##
Provided your github account is allowed to access the enterprise repo.

Edit 'bootstrap.sh' and fill your credentials before running vagrant up.
    
    IS_ENTERPRISE='true'
    GITHUB_USER='<fill in your username>'
    GITHUB_PASS='<fill your password>'

Else Proceed below.

## Setup Development ##
Step 1: run vagrant (it may take few minutes)

    $ vagrant up

Step 2: ssh vagrant

    $ vagrant ssh

Step 3: open web browser

    http://localhost:8069

## Credentials ##
1. Postgresql (localhost)
    - User: odoo
    - Password: odoo

## Running Odoo ##

    $ /vagrant/odoo/odoo-bin -c /vagrant/conf/odoo.conf

## Creating your first Module ##
    
    $ /vagrant/odoo/odoo-bin scaffold module_name /vagrant/_extra_addons

    
Other References: <br/>
https://github.com/JamesGreenAU/OdooVagrant <br/>
https://github.com/Yenthe666/InstallScript
