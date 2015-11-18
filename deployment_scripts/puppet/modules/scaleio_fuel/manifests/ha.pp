class scaleio_fuel::ha (
  $controllers         = $scaleio_fuel::params::controller_nodes,
  ) {

  $primary_controller = filter_nodes($controllers,'role','primary-controller')

  class { 'cluster::haproxy_ocf':
    primary_controller => $primary_controller
  }

  Haproxy::Service        { use_include => true }
  Haproxy::Balancermember { use_include => true }

  Openstack::Ha::Haproxy_service {
    server_names        => filter_hash($controllers, 'name'),
    ipaddresses         => filter_hash($controllers, 'internal_address'),
    public_virtual_ip   => $::fuel_settings['public_vip'],
    internal_virtual_ip => $::fuel_settings['management_vip'],
  }

  openstack::ha::haproxy_service { 'scaleio-gateway':
    order                  => 201,
    listen_port            => 443,
    balancermember_port    => 443,
    define_backups         => true,
    before_start           => true,
    public                 => true,
    haproxy_config_options => {
      'balance' => 'roundrobin',
      'option'  => ['httplog'],
    },
    balancermember_options => 'check',
  }

}
