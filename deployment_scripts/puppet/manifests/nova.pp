# The puppet configures OpenStack nova to use ScaleIO.

$scaleio = hiera('scaleio')
if $scaleio['metadata']['enabled'] {
  $all_nodes = hiera('nodes')
  $nodes = filter_nodes($all_nodes, 'name', $::hostname)
  if empty(filter_nodes($nodes, 'role', 'compute')) {
    fail("Compute Role is not found on the host ${::hostname}")
  }
  if $scaleio['provisioning_type'] and $scaleio['provisioning_type'] != '' {
    $provisioning_type = $scaleio['provisioning_type']
  } else {
    $provisioning_type = undef
  }
  $gateway_ip = $scaleio['existing_cluster'] ? {
    true  => $scaleio['gateway_ip'],
    default => hiera('management_vip')
  }
  class {'scaleio_openstack::nova':
    ensure              => present,
    gateway_user        => $::gateway_user,
    gateway_password    => $scaleio['password'],
    gateway_ip          => $gateway_ip,
    gateway_port        => $::gateway_port,
    protection_domains  => $scaleio['protection_domain'],
    storage_pools       => $::storage_pools,
    provisioning_type   => $provisioning_type,
 }
}
