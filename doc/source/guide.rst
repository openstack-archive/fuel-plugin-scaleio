User Guide
==========

Once the Fuel ScaleIOv2.0 plugin has been installed (following the
:ref:`Installation Guide <installation>`), you can create an *OpenStack* environments that
uses ScaleIO as the block storage backend.

Prepare infrastructure
----------------------

At least 5 nodes are required to successfully deploy Mirantis OpenStack with ScaleIO (for 3-controllers mode cluster).

#. Fuel master node (w/ 50GB Disk, 2 Network interfaces [Mgmt, PXE] )
#. OpenStack Controller #1 node
#. OpenStack Controller #2 node
#. OpenStack Controller #3 node
#. OpenStack Compute node

Each node shall have at least 2 CPUs, 4GB RAM, 200GB disk, 3 Network interfaces. Each node which is supposed to host ScaleIO SDS should have at least one empty disk of minimum 100GB size. 
The 3 interfaces will be used for the following purposes:

#. Admin (PXE) network: Mirantis OpenStack uses PXE booting to install the operating system, and then loads the OpenStack packages for you.
#. Public, Management and Storage networks: All of the OpenStack management traffic will flow over this network (“Management” and “Storage” will be separated by VLANs), and to re-use the network it will also host the public network used by OpenStack service nodes and the floating IP address range.
#. Private network: This network will be added to Virtual Machines when they boot. It will therefore be the route where traffic flows in and out of the VM.

In case of new ScaleIO cluster deployment Controllers 1, 2, and 3 will be for hosting ScaleIO MDM and ScaleIO Gateway services.
Cinder role should be deployed if ScaleIO volume functionality is required.
All Compute nodes are used as ScaleIO SDS. It is possible to enable ScaleIO SDS on Controllers node. Keep in mind that 3 SDSs is a minimal required configuration so if you have less than 3 compute nodes you have to deploy ScaleIO SDS on controllers as well. All nodes that will be used as ScaleIO SDS should have equal disk configuration. All disks that will be used as SDS devices should be unallocated in Fuel.

In case of existing ScaleIO cluster deployment the plugin deploys ScaleIO SDC component onto Compute and Cinder nodes and configures OpenStack Cinder and Nova to use ScaleIO as the block storage backend. 

The ScaleIO cluster will use the storage network for all volume and cluster maintenance operations.

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

#. Create a new environment with the Fuel UI wizard.
From OpenStack Release dropdown list select "Liberty on Ubunu 14.04" and continue until you finish with the wizard.

    .. image:: images/wizard.png
       :width: 80%

#. Add VMs to the new environment according to `Fuel User Guide <https://docs.mirantis.com/openstack/fuel/fuel-8.0/operations.html#adding-redeploying-and-replacing-nodes>`_ and configure them properly.


Plugin configuration
--------------------

\1. Go to the Settings tab and then go to the section Storage. You need to fill all fields with your preferred ScaleIO configuration. If you do not know the purpose of a field you can leave it with its default value.

    .. image:: images/settings1.png
       :width: 80%

\2. In order to deploy new ScaleIO cluster together with OpenStack

  \a. Disable the checkbox 'Use existing ScaleIO'

  \b. Provide Admin passwords for ScaleIO MDM and Gateway, list of Storage devices to be used as ScaleIO SDS storage devices. Optionally you can provide protection domain name and storage pool names.

    .. image:: images/settings2.png
       :width: 80%

    .. image:: images/settings3.png
       :width: 80%

  \c. In case you want to specify different storage pools for different devices provide a list of pools corresponding to device paths, e.g. 'pool1,pool2' and '/dev/sdb,/dev/sdc' will assign /dev/sdb for the pool1 and /dev/sdc for the pool2.

  \d. Make disks for ScaleIO SDS devices unallocated. These disks will be cleaned up and added to SDSs as storage devices. Note, that because of current Fuel framework limitation it is needed to keep some space for Cinder and Nova roles.

    .. image:: images/devices_compute.png
       :width: 80%

    .. image:: images/devices_controller.png
       :width: 80%

\3. In order to use existing ScaleIO cluster

  \a. Enable checkbox 'Use existing ScaleIO'

  \b. Provide IP address and password for ScaleIO Gateway, protection domain name and storage pool names that will be allowed to be used in OpenStack. The first storage pool name will become the default storage pool for volumes.

    .. image:: images/settings_existing_cluster.png
       :width: 80%

\4. Take the time to review and configure other environment settings such as the DNS and NTP servers, URLs for the repositories, etc.


Finish environment configuration
--------------------------------

#. Go to the Network tab and configure the network according to your environment.

#. Run `network verification check <https://docs.mirantis.com/openstack/fuel/fuel-8.0/pdf/Fuel-8.0-UserGuide.pdf#Verify network configuration>`_

    .. image:: images/network.png
       :width: 90%

#. Press `Deploy button <https://docs.mirantis.com/openstack/fuel/fuel-8.0/pdf/Fuel-8.0-UserGuide.pdf#Deploy changes>`_ once you have finished reviewing the environment configuration.

    .. image:: images/deploy.png
       :width: 60%

#. After deployment is done, you will see a message indicating the result of the deployment.

    .. image:: images/deploy-result.png
       :width: 80%


ScaleIO verification
--------------------

Once the OpenStack cluster is set up, you can make use of ScaleIO volumes. This is an example about how to attach a volume to a running VM.

#. Perform OpenStack Health Check via FUEL UI. Note, that it is needed to keep un-selected tests that are related to running of instances because they use a default instance flavour but ScaleIO requires a flavour with volume sizes that are multiple of 8GB. FUEL does not allow to configure these tests from the plugin.

#. Login into the OpenStack cluster:

#. Review the block storage services by navigating to the "Admin -> System -> System Information" section. You should see the "@ScaleIO" appended to all cinder-volume hosts.

    .. image:: images/block-storage-services.png
       :width: 90%

#. Connect to ScaleIO cluster in the ScaleIO GUI (see :ref:`Install ScaleIO GUI section <scaleiogui>`). In case of new ScaleIO cluster deployment use the IP address of the master ScaleIO MDM (initially it's the controller node with the minimal IP-address but master MDM can switch to another controller), username `admin`, and the password you entered in the Fuel UI.

#. Once logged in, verify that it successfully reflects the ScaleIO resources:

    .. image:: images/scaleio-cp.png
       :width: 80%

#. For the case of new ScaleIO cluster deployment click on the "Backend" tab and verify all SDS nodes:

    .. image:: images/scaleio-sds.png
       :width: 90%

#. Create a new OpenStack volume (ScaleIO backend is used by default).

#. In the ScaleIO GUI, you will see that there is one volume defined but none have been mapped yet.

    .. image:: images/sio-volume-defined.png
       :width: 20%

#. Once the volume is attached to a VM, the ScaleIO GUI will reflect the mapping.

    .. image:: images/sio-volume-mapped.png
       :width: 20%


Troubleshooting
---------------

1. Deployment cluster fails.
  * Verify network settings.
  * Ensure that the nodes have internet access.
  * Ensure that there are at least 3 nodes with SDS in the cluster. All Compute nodes play SDS role, Controller nodes play SDS role in case if the option 'Controller as Storage' is enabled in the Plugin's settings.
  * For the nodes that play SDS role ensure that disks which are listed in the Plugin's settings 'Storage devices' and 'XtremCache devices' are unallocated and their sizes are greater than 100GB.
  * Ensure that controller nodes have at least 3GB RAM.

2. Deploying changes fails with timeout errors if remove a controller node (only if there were 3 controllers in cluster).
  * Connect via ssh to the one of controller nodes
  * Get MDM IPs:
    ::
      cat /etc/environment | grep SCALEIO_mdm_ips
      
  * Request ScaleIO cluster state
    ::
      scli --mdm_ip <ip_of_alive_mdm> --query_cluster
      
  * If cluster is in Degraded mode and there is one of Slave MDMs is disconnected then switch the cluster into the mode '1_node':
    ::
      scli --switch_cluster_mode --cluster_mode 1_node
           --remove_slave_mdm_ip <ips_of_slave_mdms>
           --remove_tb_ip <ips_of_tie_breakers>
      Where ips_of_slave_mdms and ips_of_tie_breakers are comma separated lists
      of slave MDMs and Tie Breakers respectively (IPs should be taken from
      query_cluster command above).
      
3. ScaleIO cluster does not see new SDS after deploying new Compute node.
	It is needed to run update hosts task on controller nodes manually on the FUEL master node, e.g. 'fuel --env 5 node --node-id 1,2,3 --task update_hosts'. This is because FUEL does not trigger plugin's tasks after Compute node deploymet.

4. ScaleIO cluster has SDS/SDC components in disconnected state after nodes deletion.
	See previous point.

5. Other issues.
	Ensure that ScaleIO cluster is operational and there are storage pool and protection domain available. For more details see ScaleIO user guide.
