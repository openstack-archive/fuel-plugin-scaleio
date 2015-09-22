$fuel_settings 			= parseyaml(file('/etc/astute.yaml'))
class {'scaleio_fuel::tb': }
