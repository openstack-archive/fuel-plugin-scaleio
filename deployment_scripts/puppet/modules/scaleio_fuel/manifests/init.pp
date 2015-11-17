class scaleio_fuel
inherits scaleio_fuel::params {

  case $role {
    'mdm':     { include scaleio_fuel::mdm }
    'tb':      { include scaleio_fuel::tb }
    'sds':     { include scaleio_fuel::sds }
  }
}
