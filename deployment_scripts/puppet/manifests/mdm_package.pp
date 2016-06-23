# The puppet installs ScaleIO MDM packages.

$scaleio = hiera('scaleio')
if $scaleio['metadata']['enabled'] {
  if ! $scaleio['existing_cluster'] {
    $node_ips = split($::ip_address_array, ',')
    if ! empty(intersection(split($::controller_ips, ','), $node_ips))    
    {
      notify {"Mdm server installation": } ->
      class {'scaleio::mdm_server':
        ensure                   => 'present',
      }
    } else {
      notify{'Skip deploying mdm server because it is not controller': }
    }
  } else {
    notify{'Skip deploying mdm server because of using existing cluster': }
  }
}
