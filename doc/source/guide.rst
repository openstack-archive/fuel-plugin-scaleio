User Guide
==========

Once the Fuel ScaleIO plugin has been installed (following the
:ref:`Installation Guide <installation>`), you can create an *OpenStack* environments that
uses ScaleIO as the block storage backend.

Prepare infrastructure
----------------------

At least 5 nodes are required to successfully deploy Mirantis OpenStack with ScaleIO.

#. Fuel master node (w/ 50GB Disk, 2 Network interfaces [Mgmt, PXE] )
#. OpenStack Controller #1 node
#. OpenStack Controller #2 node
#. OpenStack Controller #3 node
#. OpenStack Compute node

Each node shall have at least 2 CPUs, 4GB RAM, 200GB disk, 4 Network interfaces. The 4 networks are:

#. PXE Network
#. Public Network
#. Private Network
#. Management Network

Controllers 1, 2, and 3 will be used as ScaleIO MDMs, being the primary, secondary, and tie-breaker, respectively. Moreover, they will also host the ScaleIO Gateway in HA mode.

All nodes are used as ScaleIO SDS and, therefore, contribute to the default storage pool.

.. _scaleiogui:

Install ScaleIO GUI
-------------------

It is recommended to install the ScaleIO GUI to easily access and manage the ScaleIO cluster.

#. Make sure the machine in which you will install the ScaleIO GUI has access to the Controller nodes.
#. Download the ScaleIO for your operating system from the following link: http://www.emc.com/products-solutions/trial-software-download/scaleio.htm
#. Unzip the file and install the ScaleIO GUI component.
#. Once installed, run the application and you will be prompted with the following login window. We will use it once the deployment is completed.

    .. image:: images/scaleio-login.png
       :width: 50%



Select Environment
------------------

#. Create a new environment with the Fuel UI wizard. Select "Juno on CentOS 6.5" from OpenStack Release dropdown list and continue until you finish with the wizard.

    .. image:: images/wizard.png
       :width: 80%

#. Add VMs to the new environment according to `Fuel User Guide <https://docs.mirantis.com/openstack/fuel/fuel-6.1/user-guide.html#add-nodes-to-the-environment>`_ and configure them properly.


Plugin configuration
--------------------

#. Go to the Settings tab and scroll down to "ScaleIO plugin" section. You need to fill all fields with your preferred ScaleIO configuration. If you do not know the purpose of a field you can leave it with its default value.

    .. image:: images/settings.png
       :width: 70%

#. Take the time to review and configure other environment settings such as the DNS and NTP servers, URLs for the repositories, etc.


Finish environment configuration
--------------------------------

#. Go to the Network tab and configure the network according to your environment.

#. Run `network verification check <https://docs.mirantis.com/openstack/fuel/fuel-6.1/user-guide.html#verify-networks>`_

    .. image:: images/network.png
       :width: 90%

#. Press `Deploy button <https://docs.mirantis.com/openstack/fuel/fuel-6.1/user-guide.html#deploy-changes>`_ once you have finished reviewing the environment configuration.

    .. image:: images/deploy.png
       :width: 60%

#. After deployment is done, you will see a message indicating the result of the deployment.

    .. image:: images/deploy-result.png
       :width: 80%


ScaleIO verification
--------------------

Once the OpenStack cluster is setup, we can make use of ScaleIO volumes. This is an example about how to attach a volume to a running VM.

#. Login into the OpenStack cluster:

#. Review the block storage services by navigating to the "Admin -> System -> System Information" section. You should see the "@ScaleIO" appended to all cinder-volume hosts.

    .. image:: images/block-storage-services.png
       :width: 90%

#. Review the System Volumes by navigating to "Admin -> System -> Volumes". You should see a volume type called "sio_thin" with the following extra specs.

    .. image:: images/volume-type.png
       :width: 70%

#. In the ScaleIO GUI (see :ref:`Install ScaleIO GUI section <scaleiogui>`), enter the IP address of the primary controller node, username `admin`, and the password you entered in the Fuel UI.

#. Once logged in, verify that it successfully reflects the ScaleIO resources:

    .. image:: images/scaleio-cp.png
       :width: 80%

#. Click on the "Backend" tab and verify all SDS nodes:

    .. image:: images/scaleio-sds.png
       :width: 90%

#. Create a new OpenStack volume using the "sio_thin" volume type.

#. In the ScaleIO GUI, you will see that there is one volume defined but none have been mapped yet.

    .. image:: images/sio-volume-defined.png
       :width: 20%

#. Once the volume is attached to a VM, the ScaleIO GUI will reflect the mapping.

    .. image:: images/sio-volume-mapped.png
       :width: 20%
