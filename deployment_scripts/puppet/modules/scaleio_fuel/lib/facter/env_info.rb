# set of facts about deploying environment
require 'facter'

base_cmd = "bash -c 'source /etc/environment; echo $SCALEIO_%s'"
facters = ['controller_ips', 'tb_ips', 'mdm_ips', 'managers_ips',
  'gateway_user', 'gateway_port', 'gateway_ips', 'gateway_password', 'mdm_password',
  'storage_pools', 'discovery_allowed']
facters.each { |f|
  if ! Facter.value(f)
    Facter.add(f) do
      setcode base_cmd % f 
    end
  end
}

