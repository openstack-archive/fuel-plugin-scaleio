# The puppet configures OpenStack glance to use ScaleIO via Cinder.

define glance_config(
  $config_file,
) {
  Ini_setting {
    ensure  => 'present',
    section => 'glance_store',
    path    => $config_file,
  }
  ini_setting { "${config_file}: default_store":
    setting => 'default_store',
    value   => 'cinder',
  } ->
  ini_setting { "${config_file}: stores":
    setting => 'stores',
    value   => 'glance.store.cinder.Store',
  }
}


notice('MODULAR: scaleio: glance')

$scaleio = hiera('scaleio')
if $scaleio['metadata']['enabled'] {
  $all_nodes = hiera('nodes')
  $nodes = filter_nodes($all_nodes, 'name', $::hostname)
  if empty(filter_nodes($nodes, 'role', 'primary-controller')) and empty(filter_nodes($nodes, 'role', 'controller')) {
    fail("glance task should be run only on controllers, but node ${::hostname} is not controller")
  }
  if $scaleio['use_scaleio_for_glance'] {
    $glance_services = $::osfamily ? {
      'RedHat' => ['openstack-glance-api', 'openstack-glance-registry', 'openstack-glance-glare'],
      'Debian' => ['glance-api', 'glance-registry', 'glance-glare'],
    }
    $glance_api_config_file = '/etc/glance/glance-api.conf'
    $glance_glare_config_file = '/etc/glance/glance-glare.conf'
    package { ['python-cinderclient', 'python-os-brick', 'python-oslo.rootwrap']:
      ensure => 'present',
    } ->
    class {'scaleio_openstack::glance':
    } ->
    file { "/etc/glance/rootwrap.conf":
      ensure => $ensure,
      source => "puppet:///modules/scaleio_fuel/glance_rootwrap.conf",
      mode  => '0755',
      owner => 'root',
      group => 'root',
    } ->
    file { "/etc/sudoers.d/glance_sudoers":
      ensure => $ensure,
      source => "puppet:///modules/scaleio_fuel/glance_sudoers",
      mode  => '0644',
      owner => 'root',
      group => 'root',
    } ->
    glance_config {"${glance_api_config_file}":
      config_file => $glance_api_config_file
    } ->
    glance_config {"${glance_glare_config_file}":
      config_file => $glance_glare_config_file
    } ~>
    service { $glance_services:
      ensure => running,
      enable => true,
    }
  }
}
