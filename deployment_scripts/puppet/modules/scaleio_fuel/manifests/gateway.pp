class scaleio_fuel::gateway
inherits scaleio_fuel::params {

    $scaleio = $::fuel_settings['scaleio']

    class {'scaleio::params':
          gw_password => $gw_password,
          version => $version,
          mdm_ip => $mdm_ip,
          components => ['gw'],
    }

    include scaleio

}
