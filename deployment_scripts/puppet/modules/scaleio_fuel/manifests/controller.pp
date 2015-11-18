class scaleio_fuel::controller
inherits scaleio_fuel::params {

  notice("Configuring Controller node for ScaleIO integration")

  $services = ['openstack-cinder-volume', 'openstack-cinder-api', 'openstack-cinder-scheduler', 'openstack-nova-scheduler']

#2. Copy ScaleIO Files
  file { 'scaleio.py':
    path   => '/usr/lib/python2.6/site-packages/cinder/volume/drivers/emc/scaleio.py',
    source => 'puppet:///modules/scaleio_fuel/scaleio.py',
    mode   => '0644',
    owner  => 'root',
    group  => 'root',
  } ->

  file { 'scaleio.filters':
    path   => '/usr/share/cinder/rootwrap/scaleio.filters',
    source => 'puppet:///modules/scaleio_fuel/scaleio.filters',
    mode   => '0644',
    owner  => 'root',
    group  => 'root',
    before => File['cinder_scaleio.config'],
  }

# 3. Create config for ScaleIO
  $cinder_scaleio_config = "[scaleio]
rest_server_ip=$gw_ip
rest_server_username=admin
rest_server_password=$gw_password
protection_domain_name=$protection_domain
storage_pools=$protection_domain:$storage_pool
storage_pool_name=$storage_pool
round_volume_capacity=True
force_delete=True
verify_server_certificate=False
"

  file { 'cinder_scaleio.config':
    ensure  => present,
    path    => '/etc/cinder/cinder_scaleio.config',
    content => $cinder_scaleio_config,
    mode    => '0644',
    owner   => 'root',
    group   => 'root',
    before  => Ini_setting['cinder_conf_enabled_backeds'],
  } ->

  # 4. To /etc/cinder/cinder.conf add
  ini_setting { 'cinder_conf_enabled_backeds':
    ensure  => present,
    path    => '/etc/cinder/cinder.conf',
    section => 'DEFAULT',
    setting => 'enabled_backends',
    value   => 'ScaleIO',
    before  => Ini_setting['cinder_conf_volume_driver'],
  } ->

  ini_setting { 'cinder_conf_volume_driver':
    ensure  => present,
    path    => '/etc/cinder/cinder.conf',
    section => 'ScaleIO',
    setting => 'volume_driver',
    value   => 'cinder.volume.drivers.emc.scaleio.ScaleIODriver',
    before  => Ini_setting['cinder_conf_scio_config'],
  } ->

  ini_setting { 'cinder_conf_scio_config':
    ensure  => present,
    path    => '/etc/cinder/cinder.conf',
    section => 'ScaleIO',
    setting => 'cinder_scaleio_config_file',
    value   => '/etc/cinder/cinder_scaleio.config',
	  before  => Ini_setting['cinder_conf_volume_backend_name'],
  } ->

  ini_setting { 'cinder_conf_volume_backend_name':
    ensure  => present,
    path    => '/etc/cinder/cinder.conf',
    section => 'ScaleIO',
    setting => 'volume_backend_name',
    value   => 'ScaleIO',
  }~>

  service { $services:
    ensure => running,
  } ->

  class {'scaleio_fuel::ha':
    controllers => $controller_nodes,
  }
}
