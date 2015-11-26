$scaleio = hiera('scaleio')

if $scaleio['metadata']['enabled'] {
    notify{'ScaleIO plugin enabled': }

    if $::osfamily != 'RedHat' {
        fail("Unsupported osfamily: ${::osfamily} operatingsystem: ${::operatingsystem}, module ${module_name} currently only supports osfamily RedHat")
    }

    #TODO: Check that Storage pool has enough space

} else {
    notify{'ScaleIO plugin disabled': }
}
