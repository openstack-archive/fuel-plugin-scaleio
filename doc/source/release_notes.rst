Release Notes v2.1.3
====================


New Features
----------------

1. Use FTP server to download ScaleIO packages. Added appropriate option into the plugin settings to enable ability to use own FTP.


Release Notes v2.1.2
====================


New Features
----------------

1. Non-hyperconverged deployment support. Separate ScaleIO role for ScaleIO Storage nodes.
To enable this feature there is appropriate check-box in the plugin's settings.
Note, that although there is a role for ScaleIO Storage the user still has to point devices
in the 'Storage devices' settings. The role frees user from making
ScaleIO disks unassigned. User can use devices with ScaleIO role as 'Storage devices' (with
mapping to different storage pools) as well as 'XtremCache devices' (it is expected that user
is aware which device are SSD actually, the plugin does not perform such check).


Release Notes v2.1.1
====================


New Features
----------------

1. Mirantis Fuel 9.0 support.
2. RAM Cache (RMCache) support.
3. Using special FronEnd ScaleIO user in Cinder and Nova to access ScaleIO cluster instead of the 'admin' user.
4. Ability to keep Glance images on ScaleIO.

Fixed Bugs
----------------

1. Fixed algorithm of protection domain auto-creation if number of SDS-es becomes larger than a threshold in the plugin settings.
