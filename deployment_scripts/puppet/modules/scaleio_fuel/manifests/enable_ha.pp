class scaleio_fuel::enable_ha
inherits scaleio_fuel::params {

  $gw1_ip = $scaleio_fuel::params::mdm_ip[0]
  $gw2_ip = $scaleio_fuel::params::mdm_ip[1]
  $gw3_ip = $scaleio_fuel::params::tb_ip
  $nodes_hash = $::fuel_settings['nodes']

  $gw1 = filter_nodes($nodes_hash, 'internal_address', $gw1_ip)
  $gw2 = filter_nodes($nodes_hash, 'internal_address', $gw2_ip)
  $gw3 = filter_nodes($nodes_hash, 'internal_address', $gw3_ip)
  $gw_nodes = concat(concat($gw1, $gw2), $gw3)

  notify { "gw_nodes: ${gw_nodes}": }
  notify { "server_names: ${server_names}": }
  notify { "ipaddresses: ${ipaddresses}": }

  Haproxy::Service        { use_include => true }
  Haproxy::Balancermember { use_include => true }

  Openstack::Ha::Haproxy_service {
    server_names        => filter_hash($gw_nodes, 'name'),
    ipaddresses         => filter_hash($gw_nodes, 'internal_address'),
    public_virtual_ip   => $::fuel_settings['public_vip'],
    internal_virtual_ip => $::fuel_settings['management_vip'],
  }

  openstack::ha::haproxy_service { 'scaleio-gateway':
    order                  => 201,
    listen_port            => 4443,
    balancermember_port    => 4443,
    define_backups         => true,
    before_start           => true,
    public                 => true,
    haproxy_config_options => {
      'balance' => 'roundrobin',
      'option'  => ['httplog'],
    },
    balancermember_options => 'check',
  }

  exec { 'haproxy reload':
    command   => 'export OCF_ROOT="/usr/lib/ocf"; (ip netns list | grep haproxy) && ip netns exec haproxy /usr/lib/ocf/resource.d/fuel/ns_haproxy reload',
    path      => '/usr/bin:/usr/sbin:/bin:/sbin',
    logoutput => true,
    provider  => 'shell',
    tries     => 10,
    try_sleep => 10,
    returns   => [0, ''],
  }

  Haproxy::Listen <||> -> Exec['haproxy reload']
  Haproxy::Balancermember <||> -> Exec['haproxy reload']
}
