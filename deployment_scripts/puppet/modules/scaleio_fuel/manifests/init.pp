class scaleio_fuel
inherits scaleio_fuel::params {

  $role = $scaleio_fuel::params::role

  case $role {
    'mdm':     { include scaleio_fuel::mdm }
    'tb':      { include scaleio_fuel::tb }
    default:   { include scaleio_fuel::sds }
  }
}
