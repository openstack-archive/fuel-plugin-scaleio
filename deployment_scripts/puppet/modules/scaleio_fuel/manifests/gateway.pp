class scaleio_fuel::gateway {

    $gw_password          = $scaleio_fuel::params::gw_password
    $version              = $scaleio_fuel::params::version
    $mdm_ip               = $scaleio_fuel::params::mdm_ip

    class {'::scaleio':
          gw_password => $gw_password,
          version => $version,
          mdm_ip => $mdm_ip,
          components => ['gw'],
    }
}
