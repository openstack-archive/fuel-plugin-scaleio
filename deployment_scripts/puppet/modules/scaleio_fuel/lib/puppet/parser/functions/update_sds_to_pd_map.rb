# Update the map of SDSes to protection domains according to SDS number limit in one domain

module Puppet::Parser::Functions
newfunction(:update_sds_to_pd_map, :type => :rvalue, :doc => <<-EOS
      Updates map of SDS to PD with new SDSes according to SDS number limit in one PD
    EOS
  ) do |args|
      sds_to_pd_map = {}
      sds_to_pd_map.update(args[0])
      pd_name_template = args[1]
      pd_number = 1
      sds_limit = args[2].to_i
      new_sds_array = args[3]
      #prepare map of PDs to SDSes
      pd_to_sds_map = {}
      sds_to_pd_map.each do |sds, pd|
        if not pd_to_sds_map.has_key?(pd)
          pd_to_sds_map[pd] = []
        end
        pd_to_sds_map[pd] << sds
      end
      # map new SDSes to PDs
      new_sds_array.select{|sds| not sds_to_pd_map.has_key?(sds)}.each do |sds|
        suitable_pd_array = pd_to_sds_map.select{|pd, sds_es| sds_limit == 0 or sds_es.length < sds_limit}.keys
        if suitable_pd_array.length == 0
          pd_name = nil
          while not pd_name
            proposed_name = pd_number == 1 ? pd_name_template : "%s_%s" % [pd_name_template, pd_number]
            pd_number += 1
            if not pd_to_sds_map.has_key?(proposed_name)
              pd_name = proposed_name
            end
          end
          pd_to_sds_map[pd_name] = []
          suitable_pd_array = [pd_name]
        end
        suitable_pd = suitable_pd_array[0]
        pd_to_sds_map[suitable_pd] << sds
        sds_to_pd_map[sds] = suitable_pd
      end
      return sds_to_pd_map
    end
end