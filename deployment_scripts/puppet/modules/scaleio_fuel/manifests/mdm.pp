class scaleio_fuel::mdm {

    $admin_password       = $scaleio_fuel::params::admin_password
    $version              = $scaleio_fuel::params::version
    $mdm_ip               = $scaleio_fuel::params::mdm_ip
    $tb_ip                = $scaleio_fuel::params::tb_ip
    $cluster_name         = $scaleio_fuel::params::cluster_name
    $sio_sds_device       = $scaleio_fuel::params::sio_sds_device
    $callhome_cfg         = $scaleio_fuel::params::callhome_cfg

    class {'::scaleio':
          password => $admin_password,
          version => $version,
          mdm_ip => $mdm_ip,
          tb_ip => $tb_ip,
          cluster_name => $cluster_name,
          sio_sds_device => $sio_sds_device,
          callhome_cfg => $callhome_cfg,
          components => ['mdm','sds','sdc','callhome'],
    }
}
