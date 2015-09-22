# -*- mode: ruby -*-
# vi: set ft=ruby :

$script = <<SCRIPT
sudo yum update -y
sudo yum install python-devel createrepo rpm rpm-build dpkg-devel python-pip -y
sudo pip install fuel-plugin-builder
SCRIPT

Vagrant.configure(2) do |config|

  config.vm.box = "puphpet/centos65-x64"

  config.vm.hostname = "plugin-builder"

  config.ssh.pty = true

  config.vm.synced_folder ".", "/home/vagrant/src"

  config.vm.provider "virtualbox" do |vb|
    vb.memory = "1024"
  end

  config.vm.provision "shell", inline: $script

end
