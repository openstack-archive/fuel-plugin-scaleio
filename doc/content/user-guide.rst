EMC ScaleIO Fuel Plugin User Guide
==================================

Once the Fuel ScaleIO plugin has been installed (following
`Installation Guide`_), you can create an *OpenStack* environments that
uses ScaleIO as the block storage backend.

Prepare infrastructure
----------------------

TODO


Select Environment
------------------

#. Create a new environment with the Fuel UI wizard. Select "Juno on CentOS 6.5" from OpenStack Release dropdown list. At the moment you will see most of options are disabled in the wizard.

   .. image:: images/wizard.png
      :width: 80%

#. Add VMs to the new environment according to `Fuel User Guide <https://docs.mirantis.com/openstack/fuel/fuel-6.1/user-guide.html#add-nodes-to-the-environment>`_ and configure them properly.

#. Go to Settings tab and scroll down to "ScaleIO Fuel Plugin" section. You need to fill all fields with your configuration parameters. If you don't know the purpose of a field you can leave it with its default value.

   .. image:: images/settings.png
      :width: 80%

#. TODO


Finish environment configuration
--------------------------------

#. Run `network verification check <https://docs.mirantis.com/openstack/fuel/fuel-6.1/user-guide.html#verify-networks>`_

#. Press `Deploy button <https://docs.mirantis.com/openstack/fuel/fuel-6.1/user-guide.html#deploy-changes>`_ to once you are done with environment configuration.

#. After deployment is done, you will see in Horizon that all Cinder hosts use ScaleIO as a backend.

   .. image:: images/horizon.png
      :width: 80%
