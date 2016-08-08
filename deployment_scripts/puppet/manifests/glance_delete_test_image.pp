# The puppet configures OpenStack glance to use ScaleIO via Cinder.

$scaleio = hiera('scaleio')
if $scaleio['metadata']['enabled'] {
  $all_nodes = hiera('nodes')
  $nodes = filter_nodes($all_nodes, 'name', $::hostname)
  if empty(filter_nodes($nodes, 'role', 'primary-controller')) {
    fail("delete test image task should be run only on primary-controller, but node ${::hostname} is not primary-controller")
  }
  if $scaleio['use_scaleio_for_glance'] {
    $test_image = 'TestVM'
    exec {"test image delete":
      command => "bash -c 'source /root/openrc && glance image-delete \$(glance image-list | awk \"/${test_image}/ {print(\$2)}\")'",
      onlyif  => "bash -c 'source /root/openrc && glance image-list | grep -qi ${test_image}'",
      path    => '/bin:/usr/bin:/usr/local/bin',
    }
  }
}
