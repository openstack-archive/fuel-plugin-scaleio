class scaleio_fuel::sds {

    $admin_password       = $scaleio_fuel::params::admin_password
    $version              = $scaleio_fuel::params::version
    $mdm_ip               = $scaleio_fuel::params::mdm_ip
    $sio_sds_device       = $scaleio_fuel::params::sio_sds_device

    class {'::scaleio':
          password => $admin_password,
          version => $version,
          mdm_ip => $mdm_ip,
          sio_sds_device => $sio_sds_device,
          sds_ssd_env_flag => true,
          components => ['sds','lia'],
    }
}
