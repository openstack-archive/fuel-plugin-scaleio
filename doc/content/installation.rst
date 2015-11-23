
Installation Guide
==================

Install the Plugin
------------------

To install the ScaleIO Fuel plugin:

#. Download it from the `Fuel Plugins Catalog`_
#. Copy the *rpm* file to the Fuel Master node:
   ::

      [root@home ~]# scp fuel-plugin-scaleio-0.3-0.3.0-1.noarch.rpm root@fuel-master:/tmp

#. Log into Fuel Master node and install the plugin using the
   `Fuel CLI <https://docs.mirantis.com/openstack/fuel/fuel-6.1/user-guide.html#using-fuel-cli>`_:

   ::

      [root@fuel-master ~]# fuel plugins --install /tmp/fuel-plugin-scaleio-0.3-0.3.0-1.noarch.rpm

#. Verify that the plugin is installed correctly:
   ::

     [root@fuel-master ~]# fuel plugins
     id | name                  | version | package_version
     ---|-----------------------|---------|----------------
     9  | fuel-plugin-scaleio   | 0.3.0   | 2.0.0


.. _Fuel Plugins Catalog: https://www.mirantis.com/products/openstack-drivers-and-plugins/fuel-plugins/
