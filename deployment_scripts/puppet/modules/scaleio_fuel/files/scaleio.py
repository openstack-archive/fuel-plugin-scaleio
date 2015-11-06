# Copyright (c) 2013 EMC Corporation
# All Rights Reserved
from requests.exceptions import ConnectionError
from cinder.version import version_info

# This software contains the intellectual property of EMC Corporation
# or is licensed to EMC Corporation from third parties.  Use of this
# software and the intellectual property contained therein is expressly
# limited to the terms and conditions of the License Agreement under which
# it is provided by or on behalf of EMC.

"""
Driver for EMC ScaleIO based on ScaleIO remote CLI.

"""

import requests
import base64
import re
import os
import time
import sys
import ConfigParser
import json
import urllib
from cinder import exception
from cinder.openstack.common import log as logging
from cinder.volume import driver
from cinder.image import image_utils
from cinder import utils
from cinder.openstack.common import processutils
from cinder import context
from cinder.volume import volume_types
from cinder import version
from oslo.config import cfg
from xml.dom.minidom import parseString

LOG = logging.getLogger(__name__)

opt = cfg.StrOpt('cinder_scaleio_config_file',
                 default='/etc/cinder/cinder_scaleio.config',
                 help='use this file for cinder scaleio driver config data')
CONFIG_SECTION_NAME = 'scaleio'
STORAGE_POOL_NAME = 'sio:sp_name'
STORAGE_POOL_ID = 'sio:sp_id'
PROTECTION_DOMAIN_NAME = 'sio:pd_name'
PROTECTION_DOMAIN_ID = 'sio:pd_id'
PROVISIONING_KEY = 'sio:provisioning'
IOPS_LIMIT_KEY = 'sio:iops_limit'
BANDWIDTH_LIMIT = 'sio:bandwidth_limit'

BLOCK_SIZE = 8
OK_STATUS_CODE = 200
VOLUME_NOT_FOUND_ERROR = 3
VOLUME_NOT_MAPPED_ERROR = 84
VOLUME_ALREADY_MAPPED_ERROR = 81


class ScaleIODriver(driver.VolumeDriver):

    """EMC ScaleIO Driver."""
    server_ip = None
    server_username = None
    server_password = None
    server_token = None
    storage_pool_name = None
    storage_pool_id = None
    protection_domain_name = None
    protection_domain_id = None
    config = None

    VERSION = "2.0"

    def __init__(self, *args, **kwargs):
        super(ScaleIODriver, self).__init__(*args, **kwargs)
        self.configuration.append_config_values([opt])

        self.config = ConfigParser.ConfigParser()
        filename = self.configuration.cinder_scaleio_config_file
        dataset = self.config.read(filename)
        # throw exception in case the config file doesn't exist
        if (len(dataset) == 0):
            raise RuntimeError("Failed to find configuration file")

        self.server_ip = self._get_rest_server_ip(self.config)
        LOG.info("REST Server IP: %s" % self.server_ip)
        self.server_port = self._get_rest_server_port(self.config)
        LOG.info("REST Server port: %s" % self.server_port)
        self.server_username = self._get_rest_server_username(self.config)
        LOG.info("REST Server username: %s" % self.server_username)
        self.server_password = self._get_rest_server_password(self.config)
        LOG.info("REST Server password: %s" % self.server_password)
        self.verify_server_certificate = self._get_verify_server_certificate(
            self.config)
        LOG.info("verify server's certificate: %s" %
                 self.verify_server_certificate)
        if (self.verify_server_certificate == 'True'):
            self.server_certificate_path = self._get_certificate_path(
                self.config)

        self.storage_pools = self._get_storage_pools(self.config)
        LOG.info("storage pools names: %s" % self.storage_pools)

        self.storage_pool_name = self._get_storage_pool_name(self.config)
        LOG.info("storage pool name: %s" % self.storage_pool_name)
        self.storage_pool_id = self._get_storage_pool_id(self.config)
        LOG.info("storage pool id: %s" % self.storage_pool_id)

        if (self.storage_pool_name is None and self.storage_pool_id is None):
            LOG.warning(
                "No storage pool name or id was found")
        self.protection_domain_name = self._get_protection_domain_name(
            self.config)
        LOG.info("protection domain name: %s" % self.protection_domain_name)
        self.protection_domain_id = self._get_protection_domain_id(self.config)
        LOG.info("protection domain id: %s" % self.protection_domain_id)
        if (self.protection_domain_name is None and
                self.protection_domain_id is None):
            LOG.warning(
                "No protection domain name or id \
                was specified in configuration")
#             raise RuntimeError("Must specify protection domain name or id")
        if (self.protection_domain_name is not None and
                self.protection_domain_id is not None):
            raise RuntimeError(
                "Cannot specify both protection domain name \
                 and protection domain id")

    def _get_rest_server_ip(self, config):
        try:
            server_ip = config.get(CONFIG_SECTION_NAME, 'rest_server_ip')
            if server_ip == '' or server_ip is None:
                LOG.debug("REST Server IP not found")
            return server_ip
        except:
            raise RuntimeError("REST Server ip must by specified")

    def _get_rest_server_port(self, config):
        warn_msg = "REST port is not set, using default 443"
        try:
            server_port = config.get(CONFIG_SECTION_NAME, 'rest_server_port')
            if server_port == '' or server_port is None:
                LOG.warning(warn_msg)
                server_port = '443'
        except ConfigParser.Error as e:
            LOG.warning(warn_msg)
            server_port = '443'
        return server_port

    def _get_rest_server_username(self, config):
        try:
            server_username = config.get(
                CONFIG_SECTION_NAME, 'rest_server_username')
            if server_username == '' or server_username is None:
                raise RuntimeError(
                    "REST Server username not found in conf file")
            return server_username
        except:
            raise RuntimeError("REST Server username must be specified")

    def _get_rest_server_password(self, config):
        try:
            server_password = config.get(
                CONFIG_SECTION_NAME, 'rest_server_password')
            return server_password
        except:
            raise RuntimeError("REST Server password must be specified")

    def _get_verify_server_certificate(self, config):
        warn_msg = "verify certificate is not set, using default of false"
        try:
            verify_server_certificate = config.get(
                CONFIG_SECTION_NAME, 'verify_server_certificate')
            if verify_server_certificate == '' or \
            verify_server_certificate is None:
                LOG.warning(warn_msg)
                verify_server_certificate = 'False'
        except ConfigParser.Error as e:
            LOG.warning(warn_msg)
            verify_server_certificate = 'False'
        return verify_server_certificate

    def _get_certificate_path(self, config):
        try:
            certificate_path = config.get(
                CONFIG_SECTION_NAME, 'server_certificate_path')
            return certificate_path
        except:
            raise RuntimeError(
                "Path to REST server's certificate must be specified")

    def _get_round_capacity(self, config):
        warn_msg = "round_volume_capacity is not set, using default of True"
        try:
            round_volume_capacity = self.config.get(
                CONFIG_SECTION_NAME, 'round_volume_capacity')
            if (round_volume_capacity == '' or round_volume_capacity is None):
                LOG.warning(warn_msg)
                round_volume_capacity = 'True'
        except ConfigParser.Error as e:
            LOG.warning(warn_msg)
            round_volume_capacity = 'True'
        return round_volume_capacity

    def _get_force_delete(self, config):
        warn_msg = "force_delete is not set, using default of False"
        try:
            force_delete = self.config.get(CONFIG_SECTION_NAME, 'force_delete')
            if (force_delete == '' or force_delete is None):
                LOG.warning(warn_msg)
                force_delete = 'False'
        except ConfigParser.Error as e:
            LOG.warning(warn_msg)
            force_delete = 'False'
        return force_delete

    def _get_unmap_volume_before_deletion(self, config):
        warn_msg = "unmap_volume_before_deletion is not set, \
        using default of False"
        try:
            unmap_before_delete = self.config.get(
                CONFIG_SECTION_NAME, 'unmap_volume_before_deletion')
            if (unmap_before_delete == '' or unmap_before_delete is None):
                LOG.warning(warn_msg)
                unmap_before_delete = 'False'
        except ConfigParser.Error as e:
            LOG.warning(warn_msg)
            unmap_before_delete = 'False'
        return unmap_before_delete

    def _get_protection_domain_id(self, config):
        warn_msg = "protection domain id not found"
        try:
            protection_domain_id = config.get(
                CONFIG_SECTION_NAME, 'protection_domain_id')
            if protection_domain_id == '' or protection_domain_id is None:
                LOG.warning(warn_msg)
                protection_domain_id = None
        except ConfigParser.Error as e:
            LOG.warning(warn_msg)
            protection_domain_id = None
        return protection_domain_id

    def _get_protection_domain_name(self, config):
        warn_msg = "protection domain name not found"
        try:
            protection_domain_name = config.get(
                CONFIG_SECTION_NAME, 'protection_domain_name')
            if protection_domain_name == '' or protection_domain_name is None:
                LOG.warning(warn_msg)
                protection_domain_name = None
        except ConfigParser.Error as e:
            LOG.warning(warn_msg)
            protection_domain_name = None
        return protection_domain_name

    def _get_storage_pools(self, config):

        storage_pools = [e.strip() for e in config.get(
            CONFIG_SECTION_NAME, 'storage_pools').split(',')]
    #    SPYS = [e.strip() for e in parser.get('global', 'spys').split(',')]

    #    storage_pools = config.get(CONFIG_SECTION_NAME, 'storage_pools')
        LOG.warning("storage pools are {0}".format(storage_pools))
        return storage_pools

    def _get_storage_pool_name(self, config):
        warn_msg = "storage pool name not found"
        try:
            storage_pool_name = config.get(
                CONFIG_SECTION_NAME, 'storage_pool_name')
            if storage_pool_name == '' or storage_pool_name is None:
                LOG.warning(warn_msg)
                storage_pool_name = None
        except ConfigParser.Error as e:
            LOG.warning(warn_msg)
            storage_pool_name = None
        return storage_pool_name

    def _get_storage_pool_id(self, config):
        warn_msg = "storage pool id not found"
        try:
            storage_pool_id = config.get(
                CONFIG_SECTION_NAME, 'storage_pool_id')
            if storage_pool_id == '' or storage_pool_id is None:
                LOG.warning(warn_msg)
                storage_pool_id = None
        except ConfigParser.Error as e:
            LOG.warning(warn_msg)
            storage_pool_id = None
        return storage_pool_id

    def _find_storage_pool_id_from_storage_type(self, storage_type):
        try:
            pool_id = storage_type[STORAGE_POOL_ID]
        except KeyError:
            # Default to what was configured in configuration file if not
            # defined
            pool_id = None
        return pool_id

    def _find_storage_pool_name_from_storage_type(self, storage_type):
        try:
            name = storage_type[STORAGE_POOL_NAME]
        except KeyError:
            # Default to what was configured in configuration file if not
            # defined
            name = None
        return name

    def _find_protection_domain_id_from_storage_type(self, storage_type):
        try:
            domain_id = storage_type[PROTECTION_DOMAIN_ID]
        except KeyError:
            # Default to what was configured in configuration file if not
            # defined
            domain_id = None
        return domain_id

    def _find_protection_domain_name_from_storage_type(self, storage_type):
        try:
            domain_name = storage_type[PROTECTION_DOMAIN_NAME]
        except KeyError:
            # Default to what was configured in configuration file if not
            # defined
            domain_name = None
        return domain_name

    def _find_provisioning_type(self, storage_type):
        try:
            provisioning_type = storage_type[PROVISIONING_KEY]
        except KeyError:
            provisioning_type = None
        return provisioning_type

    def _find_iops_limit(self, storage_type):
        try:
            iops_limit = storage_type[IOPS_LIMIT_KEY]
        except KeyError:
            iops_limit = None
        return iops_limit

    def _find_bandwidth_limit(self, storage_type):
        try:
            bandwidth_limit = storage_type[BANDWIDTH_LIMIT]
        except KeyError:
            bandwidth_limit = None
        return bandwidth_limit

    def check_for_setup_error(self):
        pass

    def id_to_base64(self, id):
        # Base64 encode the id to get a volume name less than 32 characters due
        # to ScaleIO limitation
        name = str(id).translate(None, "-")
        name = base64.b16decode(name.upper())
        encoded_name = base64.b64encode(name)
        LOG.debug(
            "Converted id {0} to scaleio name {1}".format(id, encoded_name))
        return encoded_name

    def create_volume(self, volume):
        """Creates a scaleIO volume."""
        self._check_volume_size(volume.size)

        volname = self.id_to_base64(volume.id)

        storage_type = self._get_volumetype_extraspecs(volume)
        LOG.info("volume type in create volume is %s" % storage_type)
        storage_pool_name = self._find_storage_pool_name_from_storage_type(
            storage_type)
        LOG.info("storage pool name: %s" % storage_pool_name)
        storage_pool_id = self._find_storage_pool_id_from_storage_type(
            storage_type)
        LOG.info("storage pool id: %s" % storage_pool_id)
        protection_domain_id = \
        self._find_protection_domain_id_from_storage_type(storage_type)
        LOG.info("protection domain id: %s" % protection_domain_id)
        protection_domain_name = \
        self._find_protection_domain_name_from_storage_type(storage_type)
        LOG.info("protection domain name: %s" % protection_domain_name)
        provisioning_type = self._find_provisioning_type(storage_type)

        if (self.verify_server_certificate == 'True'):
            verify_cert = self.server_certificate_path
        else:
            verify_cert = False

        if (storage_pool_name is not None and storage_pool_id is not None):
            raise RuntimeError(
                "Cannot specify both storage pool name and storage pool id")
        if (storage_pool_name is not None):
            self.storage_pool_name = storage_pool_name
            self.storage_pool_id = None
        if (storage_pool_id is not None):
            self.storage_pool_id = storage_pool_id
            self.storage_pool_name = None
        if (self.storage_pool_name is None and
                self.storage_pool_id is None):
            raise RuntimeError("Must specify storage pool name or id")

        if (protection_domain_name is not None and
                protection_domain_id is not None):
            raise RuntimeError(
                "Cannot specify both protection domain name and  \
                protection domain id")
        if (protection_domain_name is not None):
            self.protection_domain_name = protection_domain_name
            self.protection_domain_id = None
        if (protection_domain_id is not None):
            self.protection_domain_id = protection_domain_id
            self.protection_domain_name = None
        if (self.protection_domain_name is None and
                self.protection_domain_id is None):
            raise RuntimeError("Must specify protection domain name or id")

        domain_id = self.protection_domain_id
        if (domain_id is None):
            encoded_domain_name = urllib.quote(self.protection_domain_name, '')

            request = "https://" + self.server_ip + ":" + self.server_port + \
                "/api/types/Domain/instances/getByName::" + encoded_domain_name
            LOG.info("ScaleIO get domain id by name request: %s" % request)
            r = requests.get(
                request,
                auth=(
                    self.server_username,
                    self.server_token),
                verify=verify_cert)
            r = self._check_response(r, request)
#             LOG.info("Get domain by name response: %s" % r.text)
            domain_id = r.json()
            if (domain_id == '' or domain_id is None):
                msg = ("Domain with name %s wasn't found " %
                       (self.protection_domain_name))
                LOG.error(msg)
                raise exception.VolumeBackendAPIException(data=msg)
            if (r.status_code != OK_STATUS_CODE and "errorCode" in domain_id):
                msg = ("Error getting domain id from name %s: %s " %
                       (self.protection_domain_name, domain_id['message']))
                LOG.error(msg)
                raise exception.VolumeBackendAPIException(data=msg)

        LOG.info("domain id is %s" % domain_id)
        pool_name = self.storage_pool_name
        pool_id = self.storage_pool_id
        if (pool_name is not None):
            encoded_domain_name = urllib.quote(pool_name, '')
            request = "https://" + self.server_ip + ":" + self.server_port + \
                "/api/types/Pool/instances/getByName::" + \
                domain_id + "," + encoded_domain_name
            LOG.info("ScaleIO get pool id by name request: %s" % request)
            r = requests.get(
                request,
                auth=(
                    self.server_username,
                    self.server_token),
                verify=verify_cert)
            pool_id = r.json()
            if (pool_id == '' or pool_id is None):
                msg = ("Pool with name %s wasn't found in domain %s " %
                       (pool_name, domain_id))
                LOG.error(msg)
                raise exception.VolumeBackendAPIException(data=msg)
            if (r.status_code != OK_STATUS_CODE and "errorCode" in pool_id):
                msg = ("Error getting pool id from name %s: %s " %
                       (pool_name, pool_id['message']))
                LOG.error(msg)
                raise exception.VolumeBackendAPIException(data=msg)

        LOG.info("pool id is %s" % pool_id)
        if (provisioning_type == 'thin'):
            provisioning = "ThinProvisioned"
#       default volume type is thick
        else:
            provisioning = "ThickProvisioned"

        LOG.info("ScaleIO create volume command ")
        volume_size_kb = volume.size * 1048576
        params = {'protectionDomainId': domain_id, 'volumeSizeInKb': str(
            volume_size_kb), 'name': volname, 'volumeType': provisioning,
                   'storagePoolId': pool_id}

        LOG.info("Params for add volume request: %s" % params)
        headers = {'content-type': 'application/json'}

        r = requests.post(
            "https://" +
            self.server_ip +
            ":" +
            self.server_port +
            "/api/types/Volume/instances",
            data=json.dumps(params),
            headers=headers,
            auth=(
                self.server_username,
                self.server_token),
            verify=verify_cert)
        response = r.json()
        LOG.info("add volume response: %s" % response)

        if (r.status_code != OK_STATUS_CODE and "errorCode" in response):
            msg = ("Error creating volume: %s " % (response['message']))
            LOG.error(msg)
            raise exception.VolumeBackendAPIException(data=msg)

        LOG.info("Created volume: " + volname)

    def _check_volume_size(self, size):
        if (size % 8 != 0):
            round_volume_capacity = self._get_round_capacity(self.config)
            if (round_volume_capacity == 'False'):
                exception_msg = (
                    "Cannot create volume of size %s (not multiply of 8GB)" %
                    (size))
                LOG.error(exception_msg)
                raise exception.VolumeBackendAPIException(data=exception_msg)

    def create_snapshot(self, snapshot):
        """Creates a scaleio snapshot."""
        volname = self.id_to_base64(snapshot.volume_id)
        snapname = self.id_to_base64(snapshot.id)
        self._snapshot_volume(volname, snapname)

    def _snapshot_volume(self, volname, snapname):
        vol_id = self._get_volume_id(volname)
        params = {
            'snapshotDefs': [{"volumeId": vol_id, "snapshotName": snapname}]}
        headers = {'content-type': 'application/json'}
        if (self.verify_server_certificate == 'True'):
            verify_cert = self.server_certificate_path
        else:
            verify_cert = False
        request = "https://" + self.server_ip + ":" + self.server_port + \
            "/api/instances/System/action/snapshotVolumes"
        r = requests.post(
            request,
            data=json.dumps(params),
            headers=headers,
            auth=(
                self.server_username,
                self.server_token),
            verify=verify_cert)
        r = self._check_response(r, request, False, params)
        response = r.json()
        LOG.info("snapshot volume response: %s" % response)
        if (r.status_code != OK_STATUS_CODE and "errorCode" in response):
            msg = ("Failed creating snapshot for volume %s: %s" %
                   (volname, response['message']))
            LOG.error(msg)
            raise exception.VolumeBackendAPIException(data=msg)

    def _check_response(self, response, request, isGetRequest=True, params=None):
        if (response.status_code == 401 or response.status_code == 403):
            LOG.info("Token is invalid, going to re-login and get a new one")
            login_request = "https://" + self.server_ip + \
                ":" + self.server_port + "/api/login"
            if (self.verify_server_certificate == 'True'):
                verify_cert = self.server_certificate_path
            else:
                verify_cert = False
            r = requests.get(
                login_request,
                auth=(
                    self.server_username,
                    self.server_password),
                verify=verify_cert)
            token = r.json()
            self.server_token = token
            # repeat request with valid token
            LOG.info(
                "going to perform request again {0} \
                with valid token".format(request))
            if isGetRequest:
                res = requests.get(
                                   request,
                                   auth=(
                                         self.server_username,
                                         self.server_token),
                                   verify=verify_cert)
            else:
                headers = {'content-type': 'application/json'}
                res = requests.post(
                                    request,
                                    data=json.dumps(params),
                                    headers=headers,
                                    auth=(
                                          self.server_username,
                                          self.server_token),
                                    verify=verify_cert)

            return res
        return response

    def create_volume_from_snapshot(self, volume, snapshot):
        """Creates a volume from a snapshot."""
        # We interchange 'volume' and 'snapshot' because in ScaleIO
        # snapshot is a volume: once a snapshot is generated it
        # becomes a new unmapped volume in the system and the user
        # may manipulate it in the same manner as any other volume
        # exposed by the system
        volname = self.id_to_base64(snapshot.id)
        snapname = self.id_to_base64(volume.id)
        LOG.info(
            "ScaleIO create volume from snapshot: snapshot {0} \
            to volume {1}".format(
                volname,
                snapname))
        self._snapshot_volume(volname, snapname)

    def _get_volume_id(self, volname):
        #         add /api
        volname_encoded = urllib.quote(volname, '')
        volname_double_encoded = urllib.quote(volname_encoded, '')
        LOG.info("volume name after double encoding is %s " %
                 volname_double_encoded)

        request = "https://" + self.server_ip + ":" + self.server_port + \
            "/api/types/Volume/instances/getByName::" + volname_double_encoded
        LOG.info("ScaleIO get volume id by name request: %s" % request)
        if (self.verify_server_certificate == 'True'):
            verify_cert = self.server_certificate_path
        else:
            verify_cert = False
        r = requests.get(
            request,
            auth=(
                self.server_username,
                self.server_token),
            verify=verify_cert)
        r = self._check_response(r, request)

        vol_id = r.json()

        if (vol_id == '' or vol_id is None):
            msg = ("Volume with name %s wasn't found " % (volname))
            LOG.error(msg)
            raise exception.VolumeBackendAPIException(data=msg)
        if (r.status_code != OK_STATUS_CODE and "errorCode" in vol_id):
            msg = ("Error getting volume id from name %s: %s" %
                   (volname, vol_id['message']))
            LOG.error(msg)
            raise exception.VolumeBackendAPIException(data=msg)

        LOG.info("volume id is %s" % vol_id)
        return vol_id

    def extend_volume(self, volume, new_size):
        """Extends the size of an existing available ScaleIO volume."""

        self._check_volume_size(new_size)

        volname = self.id_to_base64(volume.id)

        LOG.info(
            "ScaleIO extend volume: volume {0} to size {1}".format(
                volname,
                new_size))

        vol_id = self._get_volume_id(volname)

        request = "https://" + self.server_ip + ":" + self.server_port + \
            "/api/instances/Volume::" + vol_id + "/action/setVolumeSize"
        LOG.info("change volume capacity request: %s" % request)
        volume_new_size = new_size
        params = {'sizeInGB': str(volume_new_size)}
        headers = {'content-type': 'application/json'}
        if (self.verify_server_certificate == 'True'):
            verify_cert = self.server_certificate_path
        else:
            verify_cert = False
        r = requests.post(
            request,
            data=json.dumps(params),
            headers=headers,
            auth=(
                self.server_username,
                self.server_token),
            verify=verify_cert)
        r = self._check_response(r, request, False, params)
#         LOG.info("change volume response: %s" % r.text)

        if (r.status_code != OK_STATUS_CODE):
            response = r.json()
            msg = ("Error extending volume %s: %s" %
                   (volname, response['message']))
            LOG.error(msg)
            raise exception.VolumeBackendAPIException(data=msg)

    def create_cloned_volume(self, volume, src_vref):
        """Creates a cloned volume."""
        volname = self.id_to_base64(src_vref.id)
        snapname = self.id_to_base64(volume.id)
        LOG.info(
            "ScaleIO create cloned volume: volume {0} to volume {1}".format(
                volname,
                snapname))
        self._snapshot_volume(volname, snapname)

    def delete_volume(self, volume):
        """Deletes a logical volume"""
        volname = self.id_to_base64(volume.id)
        self._delete_volume(volname)

    def _delete_volume(self, volname):
        volname_encoded = urllib.quote(volname, '')
        volname_double_encoded = urllib.quote(volname_encoded, '')
#         volname = volname.replace('/', '%252F')
        LOG.info("volume name after double encoding is %s " %
                 volname_double_encoded)

        if (self.verify_server_certificate == 'True'):
            verify_cert = self.server_certificate_path
        else:
            verify_cert = False

        # convert volume name to id
        request = "https://" + self.server_ip + ":" + self.server_port + \
            "/api/types/Volume/instances/getByName::" + volname_double_encoded
        LOG.info("ScaleIO get volume id by name request: %s" % request)
        r = requests.get(
            request,
            auth=(
                self.server_username,
                self.server_token),
            verify=verify_cert)
        r = self._check_response(r, request)
        LOG.info("get by name response: %s" % r.text)
        vol_id = r.json()
        LOG.info("ScaleIO volume id to delete is %s" % vol_id)

        if (r.status_code != OK_STATUS_CODE and "errorCode" in vol_id):
            msg = ("Error getting volume id from name %s: %s " %
                   (volname, vol_id['message']))
            LOG.error(msg)

            error_code = vol_id['errorCode']
            if (error_code == VOLUME_NOT_FOUND_ERROR):
                force_delete = self._get_force_delete(self.config)
                if (force_delete == 'True'):
                    msg = (
                        "Ignoring error in delete volume %s: volume not found due to \
                        force delete settings" %
                        (volname))
                    LOG.warning(msg)
                    return

            raise exception.VolumeBackendAPIException(data=msg)

        headers = {'content-type': 'application/json'}

        unmap_before_delete = self._get_unmap_volume_before_deletion(
            self.config)
        # ensure that the volume is not mapped to any SDC before deletion in
        # case unmap_before_deletion is enabled
        if (unmap_before_delete == 'True'):
            params = {'allSdcs': ''}
            request = "https://" + self.server_ip + ":" + self.server_port + \
                "/api/instances/Volume::" + \
                str(vol_id) + "/action/removeMappedSdc"
            LOG.info(
                "Trying to unmap volume from all sdcs before deletion: %s" %
                request)
            r = requests.post(
                request,
                data=json.dumps(params),
                headers=headers,
                auth=(
                    self.server_username,
                    self.server_token),
                verify=verify_cert)
            r = self._check_response(r, request, False, params)
            LOG.debug("Unmap volume response: %s " % r.text)

        LOG.info("ScaleIO delete volume command ")
        params = {'removeMode': 'ONLY_ME'}
        r = requests.post(
            "https://" +
            self.server_ip +
            ":" +
            self.server_port +
            "/api/instances/Volume::" +
            str(vol_id) +
            "/action/removeVolume",
            data=json.dumps(params),
            headers=headers,
            auth=(
                self.server_username,
                self.server_token),
            verify=verify_cert)
        r = self._check_response(r, request, False, params)

#         LOG.info("delete volume response: %s" % r.json())

        if (r.status_code != OK_STATUS_CODE):
            response = r.json()
            error_code = response['errorCode']
            if (error_code == 78):
                force_delete = self._get_force_delete(self.config)
                if (force_delete == 'True'):
                    msg = (
                        "Ignoring error in delete volume %s: volume not found \
                        due to force delete settings" %
                        (vol_id))
                    LOG.warning(msg)
                else:
                    msg = ("Error deleting volume %s: volume not found" %
                           (vol_id))
                    LOG.error(msg)
                    raise exception.VolumeBackendAPIException(data=msg)
            else:
                msg = ("Error deleting volume %s: %s" %
                       (vol_id, response['message']))
                LOG.error(msg)
                raise exception.VolumeBackendAPIException(data=msg)

    def delete_snapshot(self, snapshot):
        """Deletes a ScaleIO snapshot."""
        snapname = self.id_to_base64(snapshot.id)
        LOG.info("ScaleIO delete snapshot")
        self._delete_volume(snapname)

    def initialize_connection(self, volume, connector):
        """Initializes the connection and returns connection info.

        The scaleio driver returns a driver_volume_type of 'scaleio'.  """

        LOG.debug("connector is {0} ".format(connector))
        volname = self.id_to_base64(volume.id)
        properties = {}

        properties['scaleIO_volname'] = volname
        properties['hostIP'] = connector['ip']
        properties['serverIP'] = self.server_ip
        properties['serverPort'] = self.server_port
        properties['serverUsername'] = self.server_username
        properties['serverPassword'] = self.server_password
        properties['serverToken'] = self.server_token

        storage_type = self._get_volumetype_extraspecs(volume)
        LOG.info("volume type in create volume is %s" % storage_type)
        iops_limit = self._find_iops_limit(storage_type)
        LOG.info("iops limit is: %s" % iops_limit)
        bandwidth_limit = self._find_bandwidth_limit(storage_type)
        LOG.info("bandwidth limit is: %s" % bandwidth_limit)
        properties['iopsLimit'] = iops_limit
        properties['bandwidthLimit'] = bandwidth_limit

        return {
            'driver_volume_type': 'scaleio',
            'data': properties
        }

    def terminate_connection(self, volume, connector, **kwargs):
        LOG.info("scaleio driver terminate connection")
    pass

    def _update_volume_stats(self):
        stats = {}

        backend_name = self.configuration.safe_get('volume_backend_name')
        stats['volume_backend_name'] = backend_name or 'scaleio'
        stats['vendor_name'] = 'EMC'
        stats['driver_version'] = self.VERSION
        stats['storage_protocol'] = 'scaleio'
        stats['total_capacity_gb'] = 'unknown'
        stats['free_capacity_gb'] = 'unknown'
        stats['reserved_percentage'] = 0
        stats['QoS_support'] = False

        pools = []

        headers = {'content-type': 'application/json'}

        if (self.verify_server_certificate == 'True'):
            verify_cert = self.server_certificate_path
        else:
            verify_cert = False

        max_free_capacity = 0
        total_capacity = 0

        for sp_name in self.storage_pools:
            splitted_name = sp_name.split(':')
            domain_name = splitted_name[0]
            pool_name = splitted_name[1]
            LOG.debug(
                "domain name is {0}, pool name is {1}".format(
                    domain_name,
                    pool_name))
            # get domain id from name
            encoded_domain_name = urllib.quote(domain_name, '')
            request = "https://" + self.server_ip + ":" + self.server_port + \
                "/api/types/Domain/instances/getByName::" + encoded_domain_name
            LOG.info("ScaleIO get domain id by name request: %s" % request)
            LOG.info("username: %s, password: %s, verify_cert: %s " %
                     (self.server_username, self.server_token, verify_cert))
            r = requests.get(
                request,
                auth=(
                    self.server_username,
                    self.server_token),
                verify=verify_cert)
            r = self._check_response(r, request)
            LOG.info("Get domain by name response: %s" % r.text)
            domain_id = r.json()
            if (domain_id == '' or domain_id is None):
                msg = ("Domain with name %s wasn't found " %
                       (self.protection_domain_name))
                LOG.error(msg)
                raise exception.VolumeBackendAPIException(data=msg)
            if (r.status_code != OK_STATUS_CODE and "errorCode" in domain_id):
                msg = ("Error getting domain id from name %s: %s " %
                       (self.protection_domain_name, domain_id['message']))
                LOG.error(msg)
                raise exception.VolumeBackendAPIException(data=msg)
            LOG.info("domain id is %s" % domain_id)

            # get pool id from name
            encoded_pool_name = urllib.quote(pool_name, '')
            request = "https://" + self.server_ip + ":" + self.server_port + \
                "/api/types/Pool/instances/getByName::" + \
                domain_id + "," + encoded_pool_name
            LOG.info("ScaleIO get pool id by name request: %s" % request)
            r = requests.get(
                request,
                auth=(
                    self.server_username,
                    self.server_token),
                verify=verify_cert)
            pool_id = r.json()
            if (pool_id == '' or pool_id is None):
                msg = ("Pool with name %s wasn't found in domain %s " %
                       (pool_name, domain_id))
                LOG.error(msg)
                raise exception.VolumeBackendAPIException(data=msg)
            if (r.status_code != OK_STATUS_CODE and "errorCode" in pool_id):
                msg = ("Error getting pool id from name %s: %s " %
                       (pool_name, pool_id['message']))
                LOG.error(msg)
                raise exception.VolumeBackendAPIException(data=msg)
            LOG.info("pool id is %s" % pool_id)

            request = "https://" + self.server_ip + ":" + self.server_port + \
                "/api/types/StoragePool/instances/action/" + \
                "querySelectedStatistics"
            params = {'ids': [pool_id], 'properties': [
                "capacityInUseInKb", "capacityLimitInKb"]}
            r = requests.post(
                request,
                data=json.dumps(params),
                headers=headers,
                auth=(
                    self.server_username,
                    self.server_token),
                verify=verify_cert)
            response = r.json()
            LOG.info("query capacity stats response: %s" % response)
            for res in response.itervalues():
                capacityInUse = res['capacityInUseInKb']
                capacityLimit = res['capacityLimitInKb']
                total_capacity_gb = capacityLimit / 1048576
                used_capacity_gb = capacityInUse / 1048576
                free_capacity_gb = total_capacity_gb - used_capacity_gb
                LOG.info(
                    "free capacity of pool {0} is: {1}, \
                    total capacity: {2}".format(
                        pool_name,
                        free_capacity_gb,
                        total_capacity_gb))
            pool = {'pool_name': sp_name,
                    'total_capacity_gb': total_capacity_gb,
                    'free_capacity_gb': free_capacity_gb,
                    #             'total_capacity_gb': 100000,
                    #             'free_capacity_gb': 100000,
                    'QoS_support': False,
                    'reserved_percentage': 0
                    }

            pools.append(pool)
            if (free_capacity_gb > max_free_capacity):
                max_free_capacity = free_capacity_gb
            total_capacity = total_capacity + total_capacity_gb

        stats['volume_backend_name'] = backend_name or 'scaleio'
        stats['vendor_name'] = 'EMC'
        stats['driver_version'] = self.VERSION
        stats['storage_protocol'] = 'scaleio'
        # Use zero capacities here so we always use a pool.
        stats['total_capacity_gb'] = total_capacity
        stats['free_capacity_gb'] = max_free_capacity
        LOG.info(
            "free capacity for backend is: {0}, total capacity: {1}".format(
                max_free_capacity,
                total_capacity))
        stats['reserved_percentage'] = 0
        stats['QoS_support'] = False
        stats['pools'] = pools

        LOG.info("Backend name is " + stats["volume_backend_name"])

        self._stats = stats

    def get_volume_stats(self, refresh=False):
        """Get volume stats.

        If 'refresh' is True, run update the stats first.
        """
        if refresh:
            self._update_volume_stats()

        return self._stats

    def _get_volumetype_extraspecs(self, volume):
        specs = {}
        ctxt = context.get_admin_context()
        type_id = volume['volume_type_id']
        if type_id is not None:
            volume_type = volume_types.get_volume_type(ctxt, type_id)
            specs = volume_type.get('extra_specs')
            for key, value in specs.iteritems():
                specs[key] = value

        return specs

    def find_volume_path(self, volume_id):

        LOG.info("looking for volume %s" % volume_id)
        # look for the volume in /dev/disk/by-id directory
        disk_filename = ""
        tries = 0
        while not disk_filename:
            if (tries > 15):
                raise exception.VolumeBackendAPIException(
                    "scaleIO volume {0} not found \
                    at expected path ".format(volume_id))
            by_id_path = "/dev/disk/by-id"
            if not os.path.isdir(by_id_path):
                LOG.warn(
                    "scaleIO volume {0} not yet found (no directory \
                    /dev/disk/by-id yet). Try number: {1} ".format(
                        volume_id,
                        tries))
                tries = tries + 1
                time.sleep(1)
                continue
            filenames = os.listdir(by_id_path)
            LOG.warning(
                "Files found in {0} path: {1} ".format(by_id_path, filenames))
            for filename in filenames:
                if (filename.startswith("emc-vol") and
                        filename.endswith(volume_id)):
                    disk_filename = filename
            if not disk_filename:
                LOG.warn(
                    "scaleIO volume {0} not yet found. \
                    Try number: {1} ".format(
                        volume_id,
                        tries))
                tries = tries + 1
                time.sleep(1)

        if (tries != 0):
            LOG.warning(
                "Found scaleIO device {0} after {1} retries ".format(
                    disk_filename,
                    tries))
        full_disk_name = by_id_path + "/" + disk_filename
        LOG.warning("Full disk name is " + full_disk_name)
        return full_disk_name
#         path = os.path.realpath(full_disk_name)
#         LOG.warning("Path is " + path)
#         return path

    def _get_client_id(
            self, server_ip, server_username, server_password, sdc_ip):
        request = "https://" + server_ip + ":" + self.server_port + \
            "/api/types/Client/instances/getByIp::" + sdc_ip + "/"
        LOG.info("ScaleIO get client id by ip request: %s" % request)
        if (self.verify_server_certificate == 'True'):
            verify_cert = self.server_certificate_path
        else:
            verify_cert = False
        r = requests.get(
            request,
            auth=(
                server_username,
                self.server_token),
            verify=verify_cert)
        r = self._check_response(r, request)

        sdc_id = r.json()
        if (sdc_id == '' or sdc_id is None):
            msg = ("Client with ip %s wasn't found " % (sdc_ip))
            LOG.error(msg)
            raise exception.VolumeBackendAPIException(data=msg)
        if (r.status_code != 200 and "errorCode" in sdc_id):
            msg = ("Error getting sdc id from ip %s: %s " %
                   (sdc_ip, sdc_id['message']))
            LOG.error(msg)
            raise exception.VolumeBackendAPIException(data=msg)
        LOG.info("ScaleIO sdc id is %s" % sdc_id)
        return sdc_id

    def _attach_volume(self, volume, sdc_ip):
        # We need to make sure we even *have* a local path
        LOG.info("ScaleIO attach volume in scaleio cinder driver")
        volname = self.id_to_base64(volume.id)

        cmd = ['drv_cfg']
        cmd += ["--query_guid"]

        LOG.info("ScaleIO sdc query guid command: " + str(cmd))

        try:
            (out, err) = utils.execute(*cmd, run_as_root=True)
            LOG.info("map volume %s: stdout=%s stderr=%s" % (cmd, out, err))
        except processutils.ProcessExecutionError as e:
            msg = ("Error querying sdc guid: %s" % (e.stderr))
            LOG.error(msg)
            raise exception.VolumeBackendAPIException(data=msg)

        guid = out
        msg = ("Current sdc guid: %s" % (guid))
        LOG.info(msg)

        params = {'guid': guid}

        volume_id = self._get_volume_id(volname)
        headers = {'content-type': 'application/json'}
        request = "https://" + self.server_ip + ":" + self.server_port + \
            "/api/instances/Volume::" + str(volume_id) + "/action/addMappedSdc"
        LOG.info("map volume request: %s" % request)
        if (self.verify_server_certificate == 'True'):
            verify_cert = self.server_certificate_path
        else:
            verify_cert = False
        r = requests.post(
            request,
            data=json.dumps(params),
            headers=headers,
            auth=(
                self.server_username,
                self.server_token),
            verify=verify_cert)
        r = self._check_response(r, request, False, params)
#         LOG.info("map volume response: %s" % r.text)

        if (r.status_code != OK_STATUS_CODE):
            response = r.json()
            error_code = response['errorCode']
            if (error_code == VOLUME_ALREADY_MAPPED_ERROR):
                msg = (
                    "Ignoring error mapping volume %s: volume already mapped" %
                    (volname))
                LOG.warning(msg)
            else:
                msg = ("Error mapping volume %s: %s" %
                       (volname, response['message']))
                LOG.error(msg)
                raise exception.VolumeBackendAPIException(data=msg)

#       convert id to hex
#         val = int(volume_id)
#         id_in_hex = hex((val + (1 << 64)) % (1 << 64))
#         formated_id = id_in_hex.rstrip("L").lstrip("0x") or "0"
        formated_id = volume_id

        return self.find_volume_path(formated_id)

    def _detach_volume(self, volume, sdc_ip):
        LOG.info("ScaleIO detach volume in scaleio cinder driver")
        volname = self.id_to_base64(volume.id)

        cmd = ['drv_cfg']
        cmd += ["--query_guid"]

        LOG.info("ScaleIO sdc query guid command: " + str(cmd))

        try:
            (out, err) = utils.execute(*cmd, run_as_root=True)
            LOG.info("map volume %s: stdout=%s stderr=%s" % (cmd, out, err))
        except processutils.ProcessExecutionError as e:
            msg = ("Error querying sdc guid: %s" % (e.stderr))
            LOG.error(msg)
            raise exception.VolumeBackendAPIException(data=msg)

        guid = out
        msg = ("Current sdc guid: %s" % (guid))
        LOG.info(msg)

        params = {'guid': guid}
        headers = {'content-type': 'application/json'}

        volume_id = self._get_volume_id(volname)
        request = "https://" + self.server_ip + ":" + self.server_port + \
            "/api/instances/Volume::" + \
            str(volume_id) + "/action/removeMappedSdc"
        LOG.info("unmap volume request: %s" % request)
        if (self.verify_server_certificate == 'True'):
            verify_cert = self.server_certificate_path
        else:
            verify_cert = False
        r = requests.post(
            request,
            data=json.dumps(params),
            headers=headers,
            auth=(
                self.server_username,
                self.server_token),
            verify=verify_cert)
        r = self._check_response(r, request, False, params)

        if (r.status_code != OK_STATUS_CODE):
            response = r.json()
            error_code = response['errorCode']
            if (error_code == VOLUME_NOT_MAPPED_ERROR):
                msg = (
                    "Ignoring error unmapping volume %s: volume not mapped" %
                    (volname))
                LOG.warning(msg)
            else:
                msg = ("Error unmapping volume %s: %s" %
                       (volname, response['message']))
                LOG.error(msg)
                raise exception.VolumeBackendAPIException(data=msg)

    def copy_image_to_volume(self, context, volume, image_service, image_id):
        """Fetch the image from image_service and write it to the volume."""
        LOG.info(
            "ScaleIO copy_image_to_volume volume: " +
            str(volume) +
            " image service: " +
            str(image_service) +
            " image id: " +
            str(image_id))
        properties = utils.brick_get_connector_properties()
        sdc_ip = properties['ip']
        LOG.debug("SDC ip is: {0}".format(sdc_ip))

        cinder_version = version.version_info.version_string()
#       cinder_version = str(version.version_info)
        LOG.debug("Cinder version is %s " % cinder_version)
#       check if openstack version ia icehouse
        if (cinder_version.startswith("2014")):
            LOG.info("Cinder version is Icehouse ")
            icehouse = 'True'
        else:
            LOG.info("Cinder version is Havana or older ")
            icehouse = 'False'

        try:
            if (icehouse == 'True'):
                image_utils.fetch_to_raw(context,
                                         image_service,
                                         image_id,
                                         self._attach_volume(volume, sdc_ip),
                                         BLOCK_SIZE,
                                         size=volume['size'])
            else:
                image_utils.fetch_to_raw(context,
                                         image_service,
                                         image_id,
                                         self._attach_volume(volume, sdc_ip))

        finally:
            self._detach_volume(volume, sdc_ip)

    def copy_volume_to_image(self, context, volume, image_service, image_meta):
        """Copy the volume to the specified image."""
        LOG.info(
            "ScaleIO copy_volume_to_image volume: " +
            str(volume) +
            " image service: " +
            str(image_service) +
            " image meta: " +
            str(image_meta))
        properties = utils.brick_get_connector_properties()
        sdc_ip = properties['ip']
        LOG.debug("SDC ip is: {0}".format(sdc_ip))
        try:
            image_utils.upload_volume(context,
                                      image_service,
                                      image_meta,
                                      self._attach_volume(volume, sdc_ip))
        finally:
            self._detach_volume(volume, sdc_ip)

    def ensure_export(self, context, volume):
        """Driver entry point to get the export info for an existing volume."""
        pass

    def create_export(self, context, volume):
        """Driver entry point to get the export info for a new volume."""
        pass

    def remove_export(self, context, volume):
        """Driver entry point to remove an export for a volume."""
        pass

    def check_for_export(self, context, volume_id):
        """Make sure volume is exported."""
        pass
