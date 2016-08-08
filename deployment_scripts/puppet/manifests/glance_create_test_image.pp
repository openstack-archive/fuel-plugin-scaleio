# The puppet create new OpenStack Glance's test image.

$scaleio = hiera('scaleio')
if $scaleio['metadata']['enabled'] {
  $all_nodes = hiera('nodes')
  $nodes = filter_nodes($all_nodes, 'name', $::hostname)
  if empty(filter_nodes($nodes, 'role', 'primary-controller')) {
    fail("create test image task should be run only on primary-controller, but node ${::hostname} is not primary-controller")
  }
  if $scaleio['use_scaleio_for_glance'] {
    exec {"test image create":
      command => "ruby /etc/puppet/modules/osnailyfacter/modular/astute/upload_cirros.rb",
      path    => '/bin:/usr/bin:/usr/local/bin'
    }
  }
}
