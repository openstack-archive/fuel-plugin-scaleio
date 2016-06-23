# Convert sds_config from centralized db to form of two lists pools and devices with equal lengths

require File.join([File.expand_path(File.dirname(__FILE__)), 'convert_sds_config.rb'])

module Puppet::Parser::Functions
newfunction(:get_pools_from_sds_config, :type => :rvalue, :doc => <<-EOS
      Takes sds config as a has and returns array - first element is pools, second devices
    EOS
  ) do |args|
      config = args[0]
      result = []
      if config
        config.each do |sds, cfg|
          pools_devices = function_convert_sds_config([cfg])  # prefix function_ is required for puppet functions
                                                              # args - is arrays with required options
          if pools_devices and pools_devices[0]
            result += pools_devices[0].split(',')
          end
        end
      end
      return result.uniq
    end
end
