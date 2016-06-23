# ScaleIO Plugin for Fuel

## Overview

Disclaimer: Current version is RC1.

The `ScaleIO` plugin allows to:
  * Deploy an EMC ScaleIO v.2.0 cluster together with OpenStack and configure OpenStack to use ScaleIO
    as the storage for persistent and ephemeral volumes
  * Configure OpenStack to use an existing ScaleIO cluster as a volume backend
  * Support the following ScaleIO custer modes: 1_node, 3_node and 5_node
    the mode is chosen automatically depending on the number of controller nodes


## Requirements

| Requirement                      | Version/Comment |
|----------------------------------|-----------------|
| Mirantis OpenStack               | 6.1             |
| Mirantis OpenStack               | 7.0             |
| Mirantis OpenStack               | 8.0             |

## Recommendations

1. Use configuration with 3 controllers or 5 controllers.
    Although 1 controller mode is supported is suitable for testing purposees only.
2. Assign Cinder role for all controllers with allocating minimal diskspace for this role.
    Some space is needed because of FUEL framework limitation (this space will not used).
    Rest of the space keep for images.
3.  Use nodes with similar HW configuration within one group of roles.
4. Deploy SDS coponents only on compute nodes.
    Deploymen SDS-es on controllers is supported but it is more suitable for testing than for production environment.
5. On compute nodes keep minimal space for virtual storage on the first disk, rest disks use for ScaleIO.
    Some space is needed because of FUEL framework limitations.
    Other disks should be unallocated and can be used for ScaleIO.
6. In case of extending cluster with new compute nodes not to forget to run update_hosts tasks on controller nodes via FUEL cli. 

## Limitations

1. Plugin supports Ubuntu environment only.
2. The only hyper converged environment is supported - there is no separate ScaleIO Storage nodes.
3. Multi storage backend is not supported.
4. It is not possible to use different backends for persistent and ephemeral volumes.
5. Disks for SDS-es should be unallocated before deployment via FUEL UI or cli.
6. MDMs and Gateways are deployed together and only onto controller nodes.
7. Adding and removing node(s) to/from the OpenStack cluster won't re-configure the ScaleIO.

# Installation Guide

## ScaleIO Plugin install from source code

To install the ScaleIO Plugin from source code, you first need to prepare an environment to build the RPM file of the plugin. The recommended approach is to build the RPM file directly onto the Fuel Master node so that you won't have to copy that file later.

Prepare an environment for building the plugin on the **Fuel Master node**.

0. You might want to make sure that kernel you have on the nodes for ScaleIO SDC installation (compute and cinder nodes) is suitable for the drivers present here: ``` ftp://QNzgdxXix:Aw3wFAwAq3@ftp.emc.com/ ```. Look for something like ``` Ubuntu/2.0.5014.0/4.2.0-30-generic ```. Local kernel version can be found with ``` uname -a ``` command.

1. Install the standard Linux development tools:
    ```
    $ yum install createrepo rpm rpm-build dpkg-devel git
    ```

2. Install the Fuel Plugin Builder. To do that, you should first get pip:
    ```
    $ easy_install pip
    ```

3. Then install the Fuel Plugin Builder (the `fpb` command line) with `pip`:
    ```
    $ pip install fuel-plugin-builder
    ```

*Note: You may also have to build the Fuel Plugin Builder if the package version of the
plugin is higher than package version supported by the Fuel Plugin Builder you get from `pypi`.
In this case, please refer to the section "Preparing an environment for plugin development"
of the [Fuel Plugins wiki](https://wiki.openstack.org/wiki/Fuel/Plugins) if you
need further instructions about how to build the Fuel Plugin Builder.*

4. Clone the ScaleIO Plugin git repository:
    ```
    FUEL6.1/7.0:
    $ git clone https://github.com/cloudscaling/fuel-plugin-scaleio.git
    $ git checkout "tags/v0.3.1"
    $ cd fuel-plugin-scaleio
    ```
    ```
    FUEL8.0:
    $ git clone https://github.com/cloudscaling/fuel-plugin-scaleio.git
    $ git checkout "tags/v0.3.2"
    $ cd fuel-plugin-scaleio
    ```

5. Check that the plugin is valid:
    ```
    $ fpb --check .
    ```

6. Build the plugin:
    ```
    $ fpb --build .
    ```

7. Install plugin:
    ```
    FUEL6.1/7.0:
    $ fuel plugins --install ./scaleio-2.0-2.0.0-1.noarch.rpm
    ```
    ```
    FUEL8.0:
    $ fuel plugins --install ./scaleio-2.1-2.1.0-1.noarch.rpm
    ```

## ScaleIO Plugin install from Fuel Plugins Catalog

To install the ScaleIOv2.0 Fuel plugin:

1. Download it from the [Fuel Plugins Catalog](https://www.mirantis.com/products/openstack-drivers-and-plugins/fuel-plugins/)

2. Copy the rpm file to the Fuel Master node
    ```
    FUEL6.1/7.0
    [root@home ~]# scp scaleio-2.0-2.0.0-1.noarch.rpm root@fuel-master:/tmp
    ```
    ```
    FUEL8.0
    [root@home ~]# scp scaleio-2.1-2.1.0-1.noarch.rpm root@fuel-master:/tmp
    ```

3. Log into Fuel Master node and install the plugin using the Fuel CLI
    ```
    FUEL6.1/7.0:
    $ fuel plugins --install ./scaleio-2.0-2.0.0-1.noarch.rpm
    ```
    ```
    FUEL8.0:
    $ fuel plugins --install ./scaleio-2.1-2.1.0-1.noarch.rpm
    ```

4. Verify that the plugin is installed correctly
    ```
    FUEL6.1/7.0
    [root@fuel-master ~]# fuel plugins
    id | name                  | version | package_version
    ---|-----------------------|---------|----------------
     1 | scaleio               | 2.0.0   | 2.0.0
    ```
    ```
    FUEL8.0
    [root@fuel-master ~]# fuel plugins
    id | name                  | version | package_version
    ---|-----------------------|---------|----------------
     1 | scaleio               | 2.1.0   | 3.0.0
    ```

# User Guide

Please read the [ScaleIO Plugin User Guide](doc/source/builddir/ScaleIO-Plugin_Guide.pdf) for full description.

First of all, ScaleIOv2.0 plugin functionality should be enabled by switching on ScaleIO in the Settings.

ScaleIO section contains the following info to fill in:

1. Existing ScaleIO Cluster.

 Set "Use existing ScaleIO" checkbox.
 The following parameters should be specified:
 * Gateway IP address - IP address of ScaleIO gateway
 * Gateway port - Port of ScaleIO gateway
 * Gateway user - User to access ScaleIO gateway
 * Gateway password - Password to access ScaleIO gateway
 * Protection domain - The protection domain to use
 * Storage pools - Comma-separated list of storage pools

2. New ScaleIO deployment

 The following parameters should be specified:
 * Admin password - Administrator password to set for ScaleIO MDM
 * Protection domain - The protection domain to create for ScaleIO cluster
 * Storage pools - Comma-separated list of storage pools to create for ScaleIO cluster
 * Storage devices - Path to storage devices, comma separated (/dev/sdb,/dev/sdd)
 
 The following parameters are optional and have default values suitable for most cases:
 * Controller as Storage - Use controller nodes for ScaleIO SDS (by default only compute nodes are used for ScaleIO SDS deployment)
 * Provisioning type - Thin/Thick provisioning for ephemeral and persistent volumes
 * Checksum mode - Checksum protection. ScaleIO protects data in-flight by calculating and validating the checksum value for the payload at both ends.
   Note, the checksum feature may have a minor effect on performance. ScaleIO utilizes hardware capabilities for this feature, where possible.
 * Spare policy - % out of total space to be reserved for rebalance and redundancy recovery cases.
 * Enable Zero Padding for Storage Pools - New volumes will be zeroed if the option enabled.
 * Background device scanner - This options enables the background device scanner on the devices in device only mode.
 * XtremCache devices - List of SDS devices for SSD caching. Cache is disabled if list empty.
 * XtremCache storage pools - List of storage pools which should be cached with XtremCache.
 * Capacity high priority alert - Threshold of the non-spare capacity of the Storage Pool that will trigger a high-priority alert, in percentage format.
 * Capacity critical priority alert - Threshold of the non-spare capacity of the Storage Pool that will trigger a critical-priority alert, in percentage format.
 
 Configuration of disks for allocated nodes:
 The devices listed in the "Storage devices" and "XtremCache devices" should be left unallocated for ScaleIO SDS to work.

# Contributions

Please read the [CONTRIBUTING.md](CONTRIBUTING.md) document for the latest information about contributions.

# Bugs, requests, questions

Please use the [Launchpad project site](https://launchpad.net/fuel-plugin-scaleio) to report bugs, request features, ask questions, etc.

# License

Please read the [LICENSE](LICENSE) document for the latest licensing information.

