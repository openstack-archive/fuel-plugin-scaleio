require 'facter'

base_cmd = "bash -c 'source /root/openrc; echo $%s'"

if File.exist?("/root/openrc")
  Facter.add(:os_password) do
    setcode base_cmd % 'OS_PASSWORD'
  end

  Facter.add(:os_tenant_name) do
    setcode base_cmd % 'OS_TENANT_NAME'
  end

  Facter.add(:os_username) do
    setcode base_cmd % 'OS_USERNAME'
  end

  Facter.add(:os_auth_url) do
    setcode base_cmd % 'OS_AUTH_URL'
  end
end

