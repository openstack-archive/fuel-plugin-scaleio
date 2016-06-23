# The puppet installs ScaleIO SDC packages and connect to MDMs.
# It expects that any controller could be MDM

$scaleio = hiera('scaleio')
if $scaleio['metadata']['enabled'] {
  if ! $::controller_ips {
    fail('Empty Controller IPs configuration')    
  }
  class {'scaleio::sdc_server':
    ensure  => 'present',
    mdm_ip  => $::controller_ips,
  }
}

