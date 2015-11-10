module Puppet::Parser::Functions
  newfunction(:get_sds_devices, :type => :rvalue) do |args|
    result = {}
    nodes = args[0]
    device = args[1]
    protection_domain = args[2]
    pool_size = args[3]
    storage_pool = args[4]
    gw_ip = args[5]

    nodes.each do |node|
      if node["internal_address"] != gw_ip
        result[node["fqdn"]] = {
          "ip" => node["internal_address"],
          "protection_domain" => protection_domain,
          "devices" => {
            device => {
              "size" => pool_size,
              "storage_pool" => storage_pool
            }
          }
        }
      end
    end
    return result
  end
end
