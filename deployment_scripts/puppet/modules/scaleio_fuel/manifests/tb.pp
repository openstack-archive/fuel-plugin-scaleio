class scaleio_fuel::tb {

    $admin_password       = $scaleio_fuel::params::admin_password
    $version              = $scaleio_fuel::params::version
    $mdm_ip               = $scaleio_fuel::params::mdm_ip
    $tb_ip                = $scaleio_fuel::params::tb_ip
    $sio_sds_device       = $scaleio_fuel::params::sio_sds_device
    $callhome_cfg         = $scaleio_fuel::params::callhome_cfg

    class {'::scaleio':
          password => $admin_password,
          version => $version,
          mdm_ip => $mdm_ip,
          tb_ip => $tb_ip,
          sio_sds_device => $sio_sds_device,
          sds_ssd_env_flag => true,
          callhome_cfg => $callhome_cfg,
          components => ['tb','sds','sdc'],
    }
}
