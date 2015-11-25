class scaleio_fuel::configure_nova {

  notice("Configuring Compute node for ScaleIO integration")

  $nova_service = 'openstack-nova-compute'

  #Configure nova-compute
  ini_subsetting { 'nova-volume_driver':
    ensure               => present,
    path                 => '/etc/nova/nova.conf',
    subsetting_separator => ',',
    section              => 'libvirt',
    setting              => 'volume_drivers',
    subsetting           => 'scaleio=nova.virt.libvirt.scaleiolibvirtdriver.LibvirtScaleIOVolumeDriver',
    notify               => Service[$nova_service],
  }

  file { 'scaleiolibvirtdriver.py':
    path   => '/usr/lib/python2.6/site-packages/nova/virt/libvirt/scaleiolibvirtdriver.py',
    source => 'puppet:///modules/scaleio_fuel/scaleiolibvirtdriver.py',
    mode   => '0644',
    owner  => 'root',
    group  => 'root',
    notify => Service[$nova_service],
  }

  file { 'scaleio.filters':
    path   => '/usr/share/nova/rootwrap/scaleio.filters',
    source => 'puppet:///modules/scaleio_fuel/scaleio.filters',
    mode   => '0644',
    owner  => 'root',
    group  => 'root',
    notify => Service[$nova_service],
  }

  service { $nova_service:
    ensure => 'running',
  }
}
