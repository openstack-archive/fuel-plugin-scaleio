# The puppet installs ScaleIO SDS packages

# helping define for array processing
define sds_device_cleanup() {
  $device = $title
  exec { "device ${device} cleaup":
    command => "bash -c 'for i in \$(parted ${device} print | awk \"/^ [0-9]+/ {print(\\\$1)}\"); do parted ${device} rm \$i; done'",
    path => [ '/bin/', '/sbin/' , '/usr/bin/', '/usr/sbin/' ],
  }
}

# Just install packages
$scaleio = hiera('scaleio')
if $scaleio['metadata']['enabled'] {
  if ! $scaleio['existing_cluster'] {      
    $fuel_version = hiera('fuel_version')
    $use_plugin_roles = $fuel_version > '8.0'
    if ! $use_plugin_roles {
      #it is supposed that task is run on compute or controller
      $node_ips = split($::ip_address_array, ',')
      $is_sds_server = empty(intersection(split($::controller_ips, ','), $node_ips)) or $scaleio['sds_on_controller']
    } else {
      $all_nodes = hiera('nodes')
      $nodes = filter_nodes($all_nodes, 'name', $::hostname)
      $is_sds_server = ! empty(concat(
        concat(filter_nodes($nodes, 'role', 'scaleio-storage-tier1'), filter_nodes($nodes, 'role', 'scaleio-storage-tier2')),
        filter_nodes($nodes, 'role', 'scaleio-storage-tier3')))
    }
    if $is_sds_server {
      if ! $use_plugin_roles {
        if $scaleio['device_paths'] and $scaleio['device_paths'] != '' {
          $device_paths = split($scaleio['device_paths'], ',')
        } else {
          $device_paths = []
        }
        if $scaleio['rfcache_devices'] and $scaleio['rfcache_devices'] != '' {
          $rfcache_devices = split($scaleio['rfcache_devices'], ',')
        } else {
          $rfcache_devices = []
        }
        if ! empty($rfcache_devices) {
          $use_xcache = 'present'
        } else {
          $use_xcache = 'absent'
        }
        $devices = concat(flatten($device_paths), $rfcache_devices)
        sds_device_cleanup {$devices:
          before => Class['Scaleio::Sds_server']
        } ->
        class {'scaleio::sds_server':
          ensure  => 'present',
          xcache  => $use_xcache,
        }
      } else {
        # save devices in shared DB
        $tier1_devices = $::sds_storage_devices_tier1 ? {
          undef   => '',
          default => join(split($::sds_storage_devices_tier1, ','), ',')
        }
        $tier2_devices = $::sds_storage_devices_tier2 ? {
          undef   => '',
          default => join(split($::sds_storage_devices_tier2, ','), ',')
        }
        $tier3_devices = $::sds_storage_devices_tier3 ? {
          undef   => '',
          default => join(split($::sds_storage_devices_tier3, ','), ',')
        }
        $rfcache_devices = $::sds_storage_devices_rfcache ? {
          undef   => '',
          default => join(split($::sds_storage_devices_rfcache, ','), ',')
        }
        if $rfcache_devices and $rfcache_devices != '' {
          $use_xcache = 'present'
        } else {
          $use_xcache = 'absent'
        }
        $sds_name = $::hostname 
        $sds_config = {
          "${sds_name}" => {
            'devices' => {
              'tier1' => "${tier1_devices}",
              'tier2' => "${tier2_devices}",
              'tier3' => "${tier3_devices}",
            },
            'rfcache_devices' => "${rfcache_devices}",
          }
        }
        # convert hash to string and add escaping of qoutes
        $sds_config_str = regsubst(regsubst(inline_template('<%= @sds_config.to_s %>'), '=>', ":", 'G'), '"', '\"', 'G')
        $galera_host = hiera('management_vip')
        $mysql_opts = hiera('mysql')
        $mysql_password = $mysql_opts['root_password']
        $sql_connect = "mysql -h ${galera_host} -uroot -p${mysql_password}"  
        $db_query = 'CREATE DATABASE IF NOT EXISTS scaleio; USE scaleio'
        $table_query = 'CREATE TABLE IF NOT EXISTS sds (name VARCHAR(64), PRIMARY KEY(name), value TEXT(1024))'
        $update_query = "INSERT INTO sds (name, value) VALUES ('${sds_name}', '${sds_config_str}') ON DUPLICATE KEY UPDATE value='${sds_config_str}'"
        $sql_query = "${sql_connect} -e \"${db_query}; ${table_query}; ${update_query};\""
        class {'scaleio::sds_server':
          ensure  => 'present',
          xcache  => $use_xcache,
        } ->
        package {'mysql-client':
          ensure => present,
        } ->
        exec {'sds_devices_config':
          command => $sql_query,
          path    => '/bin:/usr/bin:/usr/local/bin',
        }
      }
    }
  } else {
    notify{'Skip sds server because of using existing cluster': }
  }
}
