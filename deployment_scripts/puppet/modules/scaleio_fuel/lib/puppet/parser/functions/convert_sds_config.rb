# Convert sds_config from centralized db to form of two lists pools and devices with equal lengths

module Puppet::Parser::Functions
newfunction(:convert_sds_config, :type => :rvalue, :doc => <<-EOS
      Takes sds config as a has and returns array - first element is pools, second devices
    EOS
  ) do |args|
      sds_config = args[0]
      result = nil
      if sds_config
        pools_devices = sds_config['devices']
        if pools_devices
          pools = nil
          devices = nil
          pools_devices.each do |pool, devs|
            devs.split(',').each do |d|
              if d and d != ""
                if ! pools
                  pools = pool.strip
                else
                  pools += ",%s" % pool.strip
                end
                if ! devices
                  devices = d.strip
                else
                  devices += ",%s" % d.strip
                end
              end
            end          
          end
          if pools and devices
            result = [pools, devices]
          end
        end
      end
      return result
    end
end