class scaleio_fuel::controller
inherits scaleio_fuel::params {

    case $role {
       'mdm':     { include scaleio_fuel::mdm }
       'tb':      { include scaleio_fuel::tb }
       'gw':      { include scaleio_fuel::gateway }
       'sds':     { include scaleio_fuel::sds }
    }

}
