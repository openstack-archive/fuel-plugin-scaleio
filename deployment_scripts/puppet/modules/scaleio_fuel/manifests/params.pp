class scaleio_fuel::params
{
    # ScaleIO config parameters
    $scaleio            = $::fuel_settings['scaleio']
    $admin_password     = $scaleio['password']
    $gw_password        = $scaleio['gw_password']
    $version            = 'latest'
    $cluster_name       = 'cluster1'
    $protection_domain  = 'pd1'
    $storage_pool       = 'sp1'
    $pool_size          = "${scaleio['pool_size']}GB"
    $device             = '/var/sio_device1'
    $volume_type        = 'sio_thin'

    $nodes_hash = $::fuel_settings['nodes']
    $controller_nodes = concat(filter_nodes($nodes_hash, 'role', 'primary-controller'), filter_nodes($nodes_hash, 'role', 'controller'))
    $controller_hashes = nodes_to_hash($controller_nodes, 'name', 'storage_address')
    $controller_ips = ipsort(values($controller_hashes))

    notify {"Controller Nodes: ${controller_nodes}": }
    notify {"Controller IPs: ${controller_ips}": }

    if size($controller_nodes) < 3 {
        fail('ScaleIO plugin needs at least 3 controller nodes')
    }

    $mdm_ip = [$controller_ips[0], $controller_ips[1]]
    $tb_ip  = $controller_ips[2]

    $current_node = filter_nodes($nodes_hash,'uid', $::fuel_settings['uid'])
    $node_ip = join(values(
      nodes_to_hash($current_node,'name','storage_address')))

    notify {"Current Node: ${current_node}": }

    case $node_ip {
      $mdm_ip[0]:       { $role = 'mdm' }
      $mdm_ip[1]:       { $role = 'mdm' }
      $tb_ip:           { $role = 'tb' }
      default:          { $role = 'sds' }
    }

    notify {"Node role: ${role}, IP: ${node_ip}, FQDN: ${::fqdn}": }

    $sio_sds_device = get_sds_devices(
      $nodes_hash, $device, $protection_domain,
      $pool_size, $storage_pool)

    notify {"SDS devices: ${sio_sds_device}": }

    #TODO: Get callhome information from UI
    $callhome_cfg = {
      'email_to'      => 'emailto@address.com',
      'email_from'    => 'emailfrom@address.com',
      'username'      => 'monitor_username',
      'password'      => 'monitor_password',
      'customer'      => 'customer_name',
      'smtp_host'     => 'smtp_host',
      'smtp_port'     => 'smtp_port',
      'smtp_user'     => 'smtp_user',
      'smtp_password' => 'smtp_password',
      'severity'      => 'error',
    }
}
