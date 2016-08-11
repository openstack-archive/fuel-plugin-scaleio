# The puppet create new OpenStack Glance's test image.

notice('MODULAR: scaleio: glance_create_test_image')

$scaleio = hiera('scaleio')
if $scaleio['metadata']['enabled'] {
  $all_nodes = hiera('nodes')
  $nodes = filter_nodes($all_nodes, 'name', $::hostname)
  if empty(filter_nodes($nodes, 'role', 'primary-controller')) {
    fail("create test image task should be run only on primary-controller, but node ${::hostname} is not primary-controller")
  }
  if $scaleio['use_scaleio_for_glance'] {
    $test_vm_image_cfg = hiera('test_vm_image')
    if $test_vm_image_cfg {
      $image_name = $test_vm_image_cfg['img_name']
      $local_path = $test_vm_image_cfg['img_path']
      $is_public_opts = $test_vm_image_cfg['public'] ? {
        false   => '--private',
        'false' => '--private',
        default => '--public',
      }
      exec {"test image create":
        command => "bash -c 'source /root/openrc && openstack image create ${is_public_opts} --file ${local_path} ${image_name}'",
        unless  => "bash -c 'source /root/openrc && openstack image list | grep -qi ${image_name}'",
        path    => '/bin:/usr/bin:/usr/local/bin',
      }
    }
  }
}
