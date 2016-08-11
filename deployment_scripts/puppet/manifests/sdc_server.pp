# The puppet installs ScaleIO SDS packages.

notice('MODULAR: scaleio: sdc_server')

$scaleio = hiera('scaleio')
if $scaleio['metadata']['enabled'] {
  class {'::scaleio::sdc_server':
    ensure => 'present',
    mdm_ip => undef,
  }
}
