class scaleio_fuel::params
{
    if $::osfamily != 'RedHat' {
        fail("Unsupported osfamily: ${::osfamily} operatingsystem: ${::operatingsystem}, module ${module_name} currently only supports osfamily RedHat")
    }

    # Get input parameters from the web UI
    $scaleio            = $::fuel_settings['scaleio']
    $admin_password     = $scaleio['password']
    $gw_password        = $scaleio['gw_password']
    $version            = $scaleio['version']
    $cluster_name       = $scaleio['cluster_name']
    $protection_domain  = $scaleio['protection_domain']
    $storage_pool       = $scaleio['storage_pool']
    $pool_size          = $scaleio['pool_size']

    $nodes_hash = $::fuel_settings['nodes']
    $controller_nodes = concat(filter_nodes($nodes_hash,'role','primary-controller'), filter_nodes($nodes_hash,'role','controller'))
    $controller_hashes = nodes_to_hash($controller_nodes,'name','internal_address')
    $controller_ips = ipsort(values($controller_hashes))

    notice("controller_nodes: ${controller_nodes}")
    notice("controller_hashes: ${controller_hashes}")
    notice("controller_ips: ${controller_ips}")

    if size($controller_nodes) < 4 {
        fail('ScaleIO plugin needs at least 4 controller nodes')
    }

    $mdm_ip = [$controller_ips[0], $controller_ips[1]]
    $tb_ip = $controller_ips[2]
    $gw_ip = $controller_ips[3]

    $current_node = filter_nodes($nodes_hash,'uid', $::fuel_settings['uid'])
    $node_ip = join(values(nodes_to_hash($current_node,'name','internal_address')))

    notice("Current Node: ${current_node}")

    #TODO: refactor needed
    if $node_ip == $mdm_ip[0] {
        $role = 'mdm'
    }
    elsif $node_ip == $mdm_ip[1] {
        $role = 'mdm'
    }
    elsif $node_ip == $tb_ip {
        $role = 'tb'
    }
    elsif $node_ip == $gw_ip {
        $role = 'gw'
    }
    else {
        $role = 'sds'
    }

    notice("Node role: ${role}, IP: ${node_ip}, FQDN: ${::fqdn}")

    $sio_sds_device = {
      "${::fqdn}" => {
        'ip' => $node_ip,
        'protection_domain' => $protection_domain,
        'devices' => {
          '/var/sio_device1' => {
            'size' => $pool_size,
            'storage_pool' => $storage_pool,
          }
        }
      }
    }


    #TODO: Get callhome information from UI
    $callhome_cfg = {
      'email_to'      => "emailto@address.com",
      'email_from'    => "emailfrom@address.com",
      'username'      => "monitor_username",
      'password'      => "monitor_password",
      'customer'      => "customer_name",
      'smtp_host'     => "smtp_host",
      'smtp_port'     => "smtp_port",
      'smtp_user'     => "smtp_user",
      'smtp_password' => "smtp_password",
      'severity'      => "error",
    }
}
