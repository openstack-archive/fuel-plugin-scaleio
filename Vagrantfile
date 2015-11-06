# -*- mode: ruby -*-
# vi: set ft=ruby :

$script = <<SCRIPT
sudo yum update -y
sudo yum install python-devel git createrepo rpm rpm-build dpkg-devel python-pip -y
git clone https://github.com/openstack/fuel-plugins.git /tmp/fpb
cd /tmp/fpb && sudo python setup.py develop
SCRIPT

Vagrant.configure(2) do |config|

  config.vm.box = "puphpet/centos65-x64"

  config.vm.hostname = "plugin-builder"

  config.ssh.pty = true

  config.vm.synced_folder ".", "/home/vagrant/src"

  config.vm.provider "virtualbox" do |vb|
    vb.memory = "1024"
  end

  config.vm.provider "vmware_appcatalyst" do |v|
    v.memory = "1024"
  end

  config.vm.provision "shell", inline: $script

end
