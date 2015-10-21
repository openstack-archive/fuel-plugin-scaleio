# Fuel Plugin for ScaleIO <a href="http://buildserver.emccode.com/viewType.html?-buildTypeId=FuelPluginsForScaleIO_FuelPluginScaleio&guest=1"><img src="http://buildserver.emccode.com/app/rest/builds/buildType:(id:FuelPluginsForScaleIO_FuelPluginScaleio)/statusIcon"/></a>

## Overview

The `ScaleIO` plugin deploys an EMC ScaleIO cluster on the available nodes and replaces the default OpenStack volume backend by ScaleIO.

If you want to leverage an existing ScaleIO cluster and deploy an OpenStack cluster to use that ScaleIO cluster, please take a look at the [ScaleIO Cinder](https://github.com/openstack/fuel-plugin-scaleio-cinder) plugin.



## Requirements

| Requirement                      | Version/Comment |
|----------------------------------|-----------------|
| Mirantis OpenStack compatibility | 6.1             |


## Recommendations

TODO.

## Limitations

ScaleIO does not support Ubuntu yet. Therefore, as Mirantis 7.0 only supports Ubuntu, this plugin is only compatible with Mirantis 6.1 with CentOS.


# Installation Guide

## ScaleIO Plugin install from RPM file

To install the ScaleIO plugin, follow these steps:

1. Download the plugin from the [Fuel Plugins Catalog](https://software.mirantis.com/download-mirantis-openstack-fuel-plug-ins/).
2. Copy the plugin file to the Fuel Master node. Follow the [Quick start guide](https://software.mirantis.com/quick-start/) if you don't have a running Fuel Master node yet.

        scp scaleio-0.1-0.1.5-0.noarch.rpm root@<Fuel Master node IP address>:

3. Install the plugin using the fuel command line.

        fuel plugins --install scaleio-0.1-0.1.5-0.noarch.rpm

4. Verify that the plugin is installed correctly.

        fuel plugins

## ScaleIO Plugin install from source code

To install the ScaleIO Plugin from source code, you first need to prepare an environment to build the RPM file of the plugin. The recommended approach is to build the RPM file directly onto the Fuel Master node so that you won't have to copy that file later.

Prepare an environment for building the plugin on the **Fuel Master node**.

1. Install the standard Linux development tools:
    ```
    yum install createrepo rpm rpm-build dpkg-devel
    ```

2. Install the Fuel Plugin Builder. To do that, you should first get pip:

    ```
    # easy_install pip
    ```

3. Then install the Fuel Plugin Builder (the `fpb` command line) with `pip`:

    ```
    # pip install fuel-plugin-builder
    ```

*Note: You may also have to build the Fuel Plugin Builder if the package version of the
plugin is higher than package version supported by the Fuel Plugin Builder you get from `pypi`.
In this case, please refer to the section "Preparing an environment for plugin development"
of the [Fuel Plugins wiki](https://wiki.openstack.org/wiki/Fuel/Plugins) if you
need further instructions about how to build the Fuel Plugin Builder.*

4. Clone the ScaleIO Plugin git repository:

    ```
    # git clone git@github.com:openstack/fuel-plugin-scaleio.git
    ```

5. Check that the plugin is valid:

    ```
    # fpb --check ./fuel-plugin-scaleio
    ```

6. And finally, build the plugin:

    ```
    # fpb --build ./fuel-plugin-scaleio
    ```

7. Now you have created an RPM file that you can install using the steps described above. The RPM file will be located in:

    ```
    ./fuel-plugin-scaleio/scaleio-0.1-0.1.5-1.noarch.rpm
    ```

# User Guide

## ScaleIO plugin configuration

1. Create a new environment with the Fuel UI wizard.
2. Click on the Settings tab of the Fuel web UI.
3. Scroll down the page, check the "ScaleIO plugin" box to  enable the plugin and fill-in the required fields.


## Contributions

Please read the the [CONTRIBUTIONS.md](CONTRIBUTIONS.md) document for the latest information about contributions.

## License

The fuel plugin for ScaleIO is licensed under the  [Apache 2.0](http://www.apache.org/licenses/LICENSE-2.0") license

Copyright (c) 2015, EMC Corporation

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
