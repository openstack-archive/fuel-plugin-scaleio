# The puppet removes OpenStack Glance's test image if it exists.
# It's needed to change default backend for images.

$scaleio = hiera('scaleio')
if $scaleio['metadata']['enabled'] {
  $all_nodes = hiera('nodes')
  $nodes = filter_nodes($all_nodes, 'name', $::hostname)
  if empty(filter_nodes($nodes, 'role', 'primary-controller')) {
    fail("delete test image task should be run only on primary-controller, but node ${::hostname} is not primary-controller")
  }
  if $scaleio['use_scaleio_for_glance'] {
    $test_vm_image_cfg = hiera('test_vm_image')
    if $test_vm_image_cfg {
      $test_image = $test_vm_image_cfg['img_name']
      exec {"test image delete":
        command => "bash -c 'source /root/openrc && openstack image delete ${test_image}'",
        onlyif  => "bash -c 'source /root/openrc && openstack image list | grep -qi ${test_image}'",
        path    => '/bin:/usr/bin:/usr/local/bin',
      }
    }
  }
}
