class scaleio_fuel::sds
inherits scaleio_fuel::params {

    $scaleio = $::fuel_settings['scaleio']

    class {'::scaleio':
          password => $admin_password,
          version => $version,
          mdm_ip => $mdm_ips,
          sio_sds_device => $sio_sds_device,
          sds_ssd_env_flag => true,
          components => ['sds','lia'],
    }

    include scaleio

}
