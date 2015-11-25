$scaleio = hiera('scaleio')

if $scaleio['metadata']['enabled'] {
    notify{'ScaleIO plugin enabled': }
    #TODO: Check that Storage pool has enough space

} else {
    notify{'ScaleIO plugin disabled': }
}
