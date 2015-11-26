===================
ScaleIO Fuel plugin
===================

ScaleIO plugin for Fuel extends Mirantis OpenStack functionality by adding
support for deploying and configuring ScaleIO clusters as block storage backend.

Problem description
===================

Currently, Fuel has no support for ScaleIO clusters as block storage backend for
OpenStack environments. ScaleIO plugin aims to provide support for it.
This plugin will deploy a ScaleIO cluster and configure the OpenStack environment
to consume the block storage services from ScaleIO.

Proposed change
===============

Implement a Fuel plugin that will deploy a ScaleIO cluster and configure the
ScaleIO Cinder driver on all Controller and Compute nodes.

Alternatives
------------
None

Data model impact
-----------------

None

REST API impact
---------------

None

Upgrade impact
--------------

None

Security impact
---------------

None

Notifications impact
--------------------

None

Other end user impact
---------------------

None

Performance Impact
------------------

The ScaleIO storage clusters provide high performance block storage for
OpenStack environments. Therefore, enabling the ScaleIO plugin in OpenStack
will greatly improve performance of OpenStack block storage operation.

Other deployer impact
---------------------

None

Developer impact
----------------

None

Implementation
==============

This plugin contains several tasks:

* The first task installs the ScaleIO cluster. All nodes will contribute to the
  storage pool by the amount specified by the user in the configuration process.
  Controllers 1, 2, and 3 will contain the MDM and the Gateway in HA mode.
* The second task configures the ScaleIO gateway to avoid interference with the
  Horizon dashboard.
* The third task enables HA in the ScaleIO gateway instances.
* The fourth task configures all Compute nodes to use ScaleIO backend.
* The fifth task configures all Controller nodes to use ScaleIO backend.
* The sixth task creates and configures a Cinder volume type with the parameters
  from the ScaleIO cluster.


Assignee(s)
-----------
| Adrian Moreno Martinez <adrian.moreno@emc.com>
| Magdy Salem <magdy.salem@emc.com>
| Patrick Butler Monterde <patrick.butlermonterde@emc.com>

Work Items
----------

* Implement the Fuel plugin.
* Implement the Puppet manifests.
* Testing.
* Write the documentation.

Dependencies
============

* Fuel 6.1.

Testing
=======

* Prepare a test plan.
* Test the plugin by deploying environments with all Fuel deployment modes.

Documentation Impact
====================

* Deployment Guide (how to install the storage backends, how to prepare an
  environment for installation, how to install the plugin, how to deploy an
  OpenStack environment with the plugin).
* User Guide (which features the plugin provides, how to use them in the
  deployed OpenStack environment).
* Test Plan.
* Test Report.
