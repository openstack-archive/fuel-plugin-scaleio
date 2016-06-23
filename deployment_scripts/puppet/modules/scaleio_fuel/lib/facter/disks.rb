require 'date'
require 'facter'

$scaleio_tier1_guid   = 'f2e81bdc-99b3-4bf6-a68f-dc794da6cd8e'
$scaleio_tier2_guid   = 'd5321bb3-1098-433e-b4f5-216712fcd06f'
$scaleio_tier3_guid   = '97987bfc-a9ba-40f3-afea-13e1a228e492'
$scaleio_rfcache_guid = '163ddeea-95dd-4af0-a329-140623590c47'

$scaleio_tiers = {
  'tier1'   => $scaleio_tier1_guid,
  'tier2'   => $scaleio_tier2_guid,
  'tier3'   => $scaleio_tier3_guid,
  'rfcache' => $scaleio_rfcache_guid,
}

$scaleio_log_file = "/var/log/fuel-plugin-scaleio.log"
def debug_log(msg)  
  File.open($scaleio_log_file, 'a') {|f| f.write("%s: %s\n" % [Time.now.strftime("%Y-%m-%d %H:%M:%S"), msg]) }
end

$scaleio_tiers.each do |tier, part_guid|
  facter_name = "sds_storage_devices_%s" % tier
  Facter.add(facter_name) do
    setcode do
      devices = nil
      res = Facter::Util::Resolution.exec("lsblk -nr -o KNAME,TYPE 2>%s | awk '/disk/ {print($1)}'" % $scaleio_log_file)
      if res and res != ''
        parts = []
        disks = res.split(' ')
        disks.each do |d|
          disk_path =  "/dev/%s" % d
          part_number = Facter::Util::Resolution.exec("partx -s %s -oTYPE,NR 2>%s | awk '/%s/ {print($2)}'" % [disk_path, $scaleio_log_file, part_guid])
          parts.push("%s%s" % [disk_path, part_number]) unless !part_number or part_number == '' 
        end
        if parts.count() > 0
          devices = parts.join(',')
        end
      end  
      debug_log("%s='%s'" % [facter_name, devices])
      devices
    end
  end
end


# facter to validate storage devices that are less than 96GB
Facter.add('sds_storage_small_devices') do
  setcode do
    result = nil
    disks1 = Facter.value('sds_storage_devices_tier1')
    disks2 = Facter.value('sds_storage_devices_tier2')
    disks3 = Facter.value('sds_storage_devices_tier3')
    if disks1 or disks2 or disks3
      disks = [disks1, disks2, disks3].join(',')
    end
    if disks
      devices = disks.split(',')
      if devices.count() > 0
        devices.each do |d|
          size = Facter::Util::Resolution.exec("partx -r -b -o SIZE %s 2>%s | grep -v SIZE" % [d, $scaleio_log_file])
          if size and size != '' and size.to_i < 96*1024*1024*1024
            if not result
              result = {}
            end
            result[d] = "%s MB" % (size.to_i / 1024 / 1024)
          end
        end
        result = result.to_s unless !result         
      end 
    end
    debug_log("%s='%s'" % ['sds_storage_small_devices', result])
    result
  end
end
