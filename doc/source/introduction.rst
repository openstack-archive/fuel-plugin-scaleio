Introduction
============

Purpose
-------
This document will guide you through the steps of install, configure and use of the **ScaleIOv2.0 Plugin** for Fuel.
The ScaleIO Plugin is used to:
 ** deploy and configure a ScaleIO cluster as a volume backend for an OpenStack environment
 ** configure an Openstack environment to use existing ScaleIO cluster as a volume backend


ScaleIO Overview
----------------
EMC ScaleIO is a software-only server-based storage area network (SAN) that converges storage and compute resources to form a single-layer, enterprise-grade storage product. ScaleIO storage is elastic and delivers linearly scalable performance. Its scale-out server SAN architecture can grow from a few to thousands of servers.

ScaleIO uses servers’ direct-attached storage (DAS) and aggregates all disks into a global, shared, block storage. ScaleIO features single-layer compute and storage architecture without requiring additional hardware or cooling/ power/space.

Breaking traditional barriers of storage scalability, ScaleIO scales out to hundreds and thousands of nodes and multiple petabytes of storage. The parallel architecture and distributed volume layout delivers a massively parallel system that deliver I/O operations through a distributed system. As a result, performance can scale linearly with the number of application servers and disks, leveraging fast parallel rebuild and rebalance without interruption to I/O. ScaleIO has been carefully designed and implemented with ScaleIO software components so as to consume minimal computing resources.

With ScaleIO, any administrator can add, move, or remove servers and capacity on demand during I/O operations. The software responds automatically to any infrastructure change and rebalances data accordingly across the grid nondisruptively. ScaleIO can add capacity on demand, without capacity planning or data migration and grow in small or large increments and pay as you grow, running on any server and with any storage media.

ScaleIO natively supports all leading Linux distributions and hypervisors. It works agnostically with any solid-state drive (SSD) or hard disk drive (HDD) regardless of type, model, or speed.


ScaleIO Components
------------------
**ScaleIO Data Client (SDC)** is a lightweight block device driver that exposes ScaleIO shared block volumes to applications. The SDS runs on the same server as the application. This enables the application to issue a IO request and the SDC fulfills it regardless of where the particular blocks physically reside. The SDC communicates with other nodes over TCP/IP-based protocol, so it is fully routable.

**ScaleIO Data Service (SDS)** owns local storage that contributes to the ScaleIO storage pools. An instance of the SDS runs on every node that contributes some, or all its storage space (HDDs, SSDs) to the aggregated pool of storage within the ScaleIO virtual SAN. The role of the SDS is to actually perform the back-end IO operations as requested by an SDC.

**ScaleIO Metadata Manager (MDM)** manages the metadata, SDC, SDS, devices mapping, volumes, snapshots, system capacity including device allocations and/or release of capacity, errors and failures, and system rebuild tasks including rebalancing. The MDM uses a Active/Passive with a tiebreaker component where the primary node is Active, and the secondary is Passive. The data repository is stored in both Active and Passive. Currently, an MDM can manage up to 1024 servers. When several MDMs are present, an SDC may be managed by several MDMs, whereas an SDS can only belong to one MDM. If the MDM does not detect the heartbeat from one SDS, it will initiate a forward-rebuild.

**ScaleIO Gateway** is the HTTP/HTTPS REST endpoint. It is the primary endpoint used by OpenStack to actuate commands against ScaleIO. Due to its stateless nature, we can have multiples instances and easily balance the load.

**Xtrem Cache (RFCache)** is the component enabling caching on PCI flash cards and/or SSDs thus accelerating the reads of SDS's HDD devices. It is deployed together with SDS component. 

ScaleIO Cinder and Nova Drivers
-------------------------------
ScaleIO includes Cinder driver, which interfaces between ScaleIO and OpenStack, and presents volumes to OpenStack as block devices which are available for block storage. It also includes an OpenStack Nova driver, for handling compute and instance volume related operations. The ScaleIO driver executes the volume operations by communicating with the backend ScaleIO MDM through the ScaleIO Gateway.


Requirements
------------

========================= ===============
Requirement               Version/Comment
========================= ===============
Mirantis OpenStack        8.0
========================= ===============


Limitations
-----------

1. Plugin is only compatible with Mirantis Fuel 8.0.
2. Plugin supports only Ubuntu environment.
3. Only hyper converged environment is supported - there is no separate ScaleIO Storage nodes.
4. Multi storage backend is not supported.
5. It is not possible to use different backends for persistent and ephemeral volumes.
6. Disks for SDS-es should be unallocated before deployment via FUEL UI or cli.
7. MDMs and Gateways are deployed together and only onto controller nodes.
8. Adding and removing node(s) to/from the OpenStack cluster won't re-configure the ScaleIO.

