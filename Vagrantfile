# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrant.configure version 2.
Vagrant.configure(2) do |config|
  config.vm.box = "ubuntu/bionic64"

  # -----------------------------------------------------------------------------------------------
  # Port forwarding
  # -----------------------------------------------------------------------------------------------
  # PostgreSQL port for remote admin on the host
  config.vm.network :forwarded_port, host: 5432, guest: 5432

  # Odoo port for remote admin on the host
  config.vm.network :forwarded_port, host: 8069, guest: 8069
  config.vm.network :forwarded_port, host: 8072, guest: 8072

  # Mail Catcher port for remote admin on the host
  config.vm.network :forwarded_port, host: 1080, guest: 1080
  config.vm.network :forwarded_port, host: 25, guest: 25

  # -----------------------------------------------------------------------------------------------
  # Virtual Box Settings (Docs: Docs: http://docs.vagrantup.com/v2/virtualbox/configuration.html)
  # -----------------------------------------------------------------------------------------------
  config.vm.provider "virtualbox" do |vb|
   vb.gui = false
   vb.memory = "4000"
   vb.name = "Odoo 11 Local Dev Environment"
   vb.cpus = 2
  end

  # -----------------------------------------------------------------------------------------------
  # Shell provisioning (Docs: http://docs.vagrantup.com/v2/provisioning/shell.html)
  # -----------------------------------------------------------------------------------------------
  config.vm.provision "shell", path: "bootstrap.sh"
end
