class scaleio_fuel::configure_gateway
inherits scaleio_fuel::params {

  $role = $scaleio_fuel::params::role

  if ($role == 'mdm') or ($role == 'tb') {

    exec { 'Change ScaleIO gateway HTTP port to 8081 (server.xml)':
      command => "sed -i 's|<Connector port=\"80\"|<Connector port=\"8081\"|g' /opt/emc/scaleio/gateway/conf/server.xml",
      path    => ['/bin'],
      onlyif  => '/usr/bin/test -f /opt/emc/scaleio/gateway/conf/server.xml',
    } ->

    exec { 'Change ScaleIO gateway HTTP port to 8081 (server_clientcert.xml)':
      command => "sed -i 's|<Connector port=\"80\"|<Connector port=\"8081\"|g' /opt/emc/scaleio/gateway/conf/server_clientcert.xml",
      path    => ['/bin'],
      onlyif  => '/usr/bin/test -f /opt/emc/scaleio/gateway/conf/server_clientcert.xml',
    } ->

    exec { 'Check port file presence':
      command => '/bin/true',
      onlyif  => '/usr/bin/test -f /opt/emc/scaleio/gateway/conf/port',
    } ->

    file { 'Update ScaleIO port file':
      path   => '/opt/emc/scaleio/gateway/conf/port',
      source => 'puppet:///modules/scaleio_fuel/port',
      mode   => '0644',
      owner  => 'root',
      group  => 'root',
    } ~>

    service { 'scaleio-gateway':
      ensure     => running,
      enable     => true,
      hasrestart => true,
    }

  } else {
    notify {'Gateway not installed. Not doing anything.':}
  }
}
