$scaleio = hiera('scaleio')

if $scaleio['metadata']['enabled'] {
    notice("ScaleIO plugin enabled in $deployment_mode mode")

    #TODO: Add checks for ScaleIO plugin
    #TODO: Check repo URL
    #TODO: Check version

} else {
    notice("ScaleIO plugin disabled")
}
