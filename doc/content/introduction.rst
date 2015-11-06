EMC ScaleIO Plugin for Fuel 6.1
===============================

EMC ScaleIO is a software-only server-based storage area network (SAN) that converges storage and compute resources to form a single-layer, enterprise-grade storage product. ScaleIO storage is elastic and delivers linearly scalable performance. Its scale-out server SAN architecture can grow from a few to thousands of servers.

ScaleIO uses servers’ direct-attached storage (DAS) and aggregates all disks into a global, shared, block storage. ScaleIO features single-layer compute and storage architecture without requiring additional hardware or cooling/ power/space.

Breaking traditional barriers of storage scalability, ScaleIO scales out to hundreds and thousands of nodes and multiple petabytes of storage. The parallel architecture and distributed volume layout delivers a massively parallel system that deliver I/O operations through a distributed system. As a result, performance can scale linearly with the number of application servers and disks, leveraging fast parallel rebuild and rebalance without interruption to I/O. ScaleIO has been carefully designed and implemented with ScaleIO software components so as to consume minimal computing resources.

With ScaleIO, any administrator can add, move, or remove servers and capacity on demand during I/O operations. The software responds automatically to any infrastructure change and rebalances data accordingly across the grid nondisruptively. ScaleIO can add capacity on demand, without capacity planning or data migration and grow in small or large increments and pay as you grow, running on any server and with any storage media.

ScaleIO natively supports all leading Linux distributions and hypervisors. It works agnostically with any solid-state drive (SSD) or hard disk drive (HDD) regardless of type, model, or speed.

ScaleIO Components
------------------

**ScaleIO Data Client (SDC)**

- Acts as Block Device Driver
- Exposes volumes to applications
- Service must run to provide access to volumes
- Over TCP/IP


**ScaleIO Data Service (SDS)**

- Abstracts storage media
- Contributes to storage pools
- Performs I/O operations

**ScaleIO Metadata Manager (MDM)**

- Not located in the data path
- Provides Monitoring and Configuration management
- Holds cluster-wide component mapping


ScaleIO Cinder Driver
---------------------

ScaleIO includes a Cinder driver, which interfaces between ScaleIO and OpenStack, and presents volumes to OpenStack as block devices which are available for block storage. It also includes an OpenStack Nova driver, for handling compute and instance volume related operations. The ScaleIO driver executes the volume operations by communicating with the backend ScaleIO MDM through the ScaleIO REST Gateway.


Requirements
------------

========================= ===============
Requirement               Version/Comment
========================= ===============
Fuel                      6.1
========================= ===============

* This plugin will deploy an EMC ScaleIO 1.32 cluster on the available nodes and replace the default OpenStack volume backend by ScaleIO.


Limitations
-----------

ScaleIO 1.32 does not support Ubuntu. Therefore, as Mirantis 7.0 only supports Ubuntu, this plugin is only compatible with Mirantis 6.1 with CentOS.
