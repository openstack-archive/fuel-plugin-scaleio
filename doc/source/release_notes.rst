Release Notes v2.0.2
====================

New Features
----------------

1. Use FTP server for downloading ScaleIO packages. Added appropriate parameter into the plugin settings to enable ability use own server.


Release Notes v2.0.1
====================


New Features
----------------

1. RAM Cache (RMCache) support.
2. Using special FronEnd ScaleIO user in Cinder and Nova to access ScaleIO cluster instead of the 'admin' user.

Fixed Bugs
----------------

1. Fixed algorithm of protection domain auto-creation if number of SDS-es becomes larger than a threshold in the plugin settings.
