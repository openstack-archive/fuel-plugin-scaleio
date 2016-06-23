# The puppet installs ScaleIO SDS packages.

$scaleio = hiera('scaleio')
if $scaleio['metadata']['enabled'] {
  class {'scaleio::sdc_server':
    ensure   => 'present',
    mdm_ip   => undef,
  }
}
