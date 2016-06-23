# The set of facts about ScaleIO cluster.
# All facts expect that MDM IPs are available via the fact 'mdm_ips'.
# If mdm_ips is absent then the facts are skipped.
# The facts about SDS/SDC and getting IPs from Gateway additionally expect that 
# MDM password is available via the fact 'mdm_password'.
#
# Facts about MDM:
# (they go over the MDM IPs one by one and request informatiom from the MDM cluster
#  via SCLI query_cluster command)
# ---------------------------------------------------------------------------------
# |    Name                       | Description
# |--------------------------------------------------------------------------------
# | scaleio_mdm_ips               | Comma separated list of MDM IPs (excepting stanby)
# | scaleio_mdm_names             | Comma separated list of MDM names (excepting stanby)
# | scaleio_tb_ips                | Comma separated list of Tie-Breaker IPs (excepting stanby)
# | scaleio_tb_names              | Comma separated list of Tie-Breaker names (excepting stanby)
# | scaleio_standby_mdm_ips       | Comma separated list of standby managers IPs
# | scaleio_standby_tb_ips        | Comma separated list of stnadby tie breakers IPs
#
# Facts about SDS and SDC:
# (they use MDM IPs as a single list and request information from a cluster via
#  SCLI query_all_sds and query_cll_sdc commands)
# ---------------------------------------------------------------------------------
# |    Name                       | Description
# |--------------------------------------------------------------------------------
# | scaleio_sds_ips               | Comma separated list of SDS IPs.
# | scaleio_sds_names             | Comma separated list of SDS names.
# | scaleio_sdc_ips               | Comma separated list of SDC IPs,
# |                               | it is list of management IPs, not storage IPs.

# Facts about MDM from Gateway:
# (It requests them from Gateway via curl and requires the fact 'gateway_ips'.
#  An user is 'admin' by default or the fact 'gateway_user' if it exists.
#  A port is 4443 or the fact 'gateway_port' if it exists.)
# ---------------------------------------------------------------------------------
# |    Name                       | Description
# |--------------------------------------------------------------------------------
# | scaleio_mdm_ips_from_gateway  | Comma separated list of MDM IP.


require 'date'
require 'facter'
require 'json'

$scaleio_log_file = "/var/log/fuel-plugin-scaleio.log"

def debug_log(msg)  
  File.open($scaleio_log_file, 'a') {|f| f.write("%s: %s\n" % [Time.now.strftime("%Y-%m-%d %H:%M:%S"), msg]) }
end


# Facter to scan existing cluster
# Controller IPs to scan
$controller_ips = Facter.value(:controller_ips)
if $controller_ips and $controller_ips != ''
  # Register all facts for MDMs
  # Example of output that facters below parse:
  #   Cluster:
  #       Mode: 3_node, State: Normal, Active: 3/3, Replicas: 2/2
  #   Master MDM:
  #       Name: 192.168.0.4, ID: 0x0ecb483853835e00
  #           IPs: 192.168.0.4, Management IPs: 192.168.0.4, Port: 9011
  #           Version: 2.0.5014
  #   Slave MDMs:
  #       Name: 192.168.0.5, ID: 0x3175fbe7695bbac1
  #           IPs: 192.168.0.5, Management IPs: 192.168.0.5, Port: 9011
  #           Status: Normal, Version: 2.0.5014
  #   Tie-Breakers:
  #       Name: 192.168.0.6, ID: 0x74ccbc567622b992
  #           IPs: 192.168.0.6, Port: 9011
  #           Status: Normal, Version: 2.0.5014
  #   Standby MDMs:
  #       Name: 192.168.0.5, ID: 0x0ce414fa06a17491, Manager
  #           IPs: 192.168.0.5, Management IPs: 192.168.0.5, Port: 9011
  #       Name: 192.168.0.6, ID: 0x74ccbc567622b992, Tie Breaker
  #           IPs: 192.168.0.6, Port: 9011
  mdm_components = {
    'scaleio_mdm_ips'           => ['/Master MDM/,/\(Tie-Breakers\)\|\(Standby MDMs\)/p', '/./,//p', 'IPs:'],
    'scaleio_tb_ips'            => ['/Tie-Breakers/,/Standby MDMs/p', '/./,//p', 'IPs:'],
    'scaleio_mdm_names'         => ['/Master MDM/,/\(Tie-Breakers\)\|\(Standby MDMs\)/p', '/./,//p', 'Name:'],
    'scaleio_tb_names'          => ['/Tie-Breakers/,/Standby MDMs/p', '/./,//p', 'Name:'],
    'scaleio_standby_mdm_ips'   => ['/Standby MDMs/,//p', '/Manager/,/Tie Breaker/p', 'IPs:'],
    'scaleio_standby_tb_ips'    => ['/Standby MDMs/,//p', '/Tie Breaker/,/Manager/p', 'IPs:'],
  }
  # Define mdm opts for SCLI tool to connect to ScaleIO cluster.
  # If there is no mdm_ips available it is expected to be run on a node with MDM Master. 
  mdm_opts = []
  $controller_ips.split(',').each do |ip|
    mdm_opts.push("--mdm_ip %s" % ip)
  end
  # the cycle over MDM IPs because for query cluster SCLI's behaiveour is strange 
  # it works for one IP but doesn't for the list.
  query_result = nil
  mdm_opts.detect do |opts|
    query_cmd = "scli %s --query_cluster --approve_certificate 2>>%s && echo success" % [opts, $scaleio_log_file]
    res = Facter::Util::Resolution.exec(query_cmd)
    debug_log("%s returns:\n'%s'" % [query_cmd, res])
    query_result = res unless !res or !res.include?('success')
  end
  if query_result
    mdm_components.each do |name, selector|
      Facter.add(name) do
        setcode do
          ip = nil
          cmd = "echo '%s' | sed -n '%s' | sed -n '%s' | awk '/%s/ {print($2)}' | tr -d ','" % [query_result, selector[0], selector[1], selector[2]]
          res = Facter::Util::Resolution.exec(cmd)
          ip = res.split(' ').join(',') unless !res
          debug_log("%s='%s'" % [name, ip])
          ip
        end
      end
    end
  end
end

# Facter to scan existing cluster
# MDM IPs to scan
$discovery_allowed = Facter.value(:discovery_allowed)
$mdm_ips = Facter.value(:mdm_ips)
$mdm_password = Facter.value(:mdm_password)
if $discovery_allowed == 'yes' and $mdm_ips and $mdm_ips != '' and $mdm_password and $mdm_password != ''
  sds_sdc_components = {
    'scaleio_sdc_ips' => ['sdc', 'IP: [^ ]*', nil],
    'scaleio_sds_ips' => ['sds', 'IP: [^ ]*', 'Protection Domain'],
    'scaleio_sds_names' => ['sds', 'Name: [^ ]*', 'Protection Domain'],
  }

  sds_sdc_components.each do |name, selector|
    Facter.add(name) do
      setcode do
        mdm_opts = "--mdm_ip %s" % $mdm_ips
        login_cmd = "scli %s --approve_certificate --login --username admin --password %s 1>/dev/null 2>>%s" % [mdm_opts, $mdm_password, $scaleio_log_file]
        query_cmd = "scli %s --approve_certificate --query_all_%s 2>>%s" % [mdm_opts, selector[0], $scaleio_log_file]
        cmd = "%s && %s" % [login_cmd, query_cmd]
        debug_log(cmd)
        result = Facter::Util::Resolution.exec(cmd)
        if result
          skip_cmd = ''
          if selector[2]
            skip_cmd = "grep -v '%s' | " % selector[2]
          end
          select_cmd = "%s grep -o '%s' | awk '{print($2)}'" % [skip_cmd, selector[1]]
          cmd = "echo '%s' | %s" % [result, select_cmd]
          debug_log(cmd)
          result = Facter::Util::Resolution.exec(cmd)
          if result
            result = result.split(' ')
            if result.count() > 0
              result = result.join(',')
            end
          end
        end
        debug_log("%s='%s'" % [name, result])
        result
      end
    end
  end

  Facter.add(:scaleio_storage_pools) do
    setcode do
      mdm_opts = "--mdm_ip %s" % $mdm_ips
      login_cmd = "scli %s --approve_certificate --login --username admin --password %s 1>/dev/null 2>>%s" % [mdm_opts, $mdm_password, $scaleio_log_file]
      query_cmd = "scli %s --approve_certificate --query_all 2>>%s" % [mdm_opts, $scaleio_log_file]
      fiter_cmd = "awk '/Protection Domain|Storage Pool/ {if($2==\"Domain\"){pd=$3}else{if($2==\"Pool\"){print(pd\":\"$3)}}}'"
      cmd = "%s && %s | %s" % [login_cmd, query_cmd, fiter_cmd]
      debug_log(cmd)
      result = Facter::Util::Resolution.exec(cmd)
      if result
        result = result.split(' ')
        if result.count() > 0
          result = result.join(',')
        end
      end
      debug_log("%s='%s'" % ['scaleio_storage_pools', result])
      result
    end
  end
end


#The fact about MDM IPs.
#It requests them from Gateway.
$gw_ips    = Facter.value(:gateway_ips)
$gw_passw  = Facter.value(:gateway_password)
if $gw_passw && $gw_passw != '' and $gw_ips and $gw_ips != ''
  Facter.add('scaleio_mdm_ips_from_gateway') do
    setcode do
      result = nil
      if Facter.value('gateway_user')
        gw_user = Facter.value('gateway_user')
      else
        gw_user = 'admin'
      end
      host = $gw_ips.split(',')[0]
      if Facter.value('gateway_port')
        port = Facter.value('gateway_port')
      else
        port = 4443
      end
      base_url = "https://%s:%s/api/%s"
      login_url = base_url % [host, port, 'login']
      config_url = base_url % [host, port, 'Configuration']
      login_req = "curl -k --basic --connect-timeout 5 --user #{gw_user}:#{$gw_passw} #{login_url} 2>>%s | sed 's/\"//g'" % $scaleio_log_file
      debug_log(login_req)
      token = Facter::Util::Resolution.exec(login_req)
      if token && token != ''
        req_url = "curl -k --basic --connect-timeout 5 --user #{gw_user}:#{token} #{config_url} 2>>%s" % $scaleio_log_file
        debug_log(req_url)
        request_result  = Facter::Util::Resolution.exec(req_url)
        if request_result
          config = JSON.parse(request_result)
          if config and config['mdmAddresses'] 
            result = config['mdmAddresses'].join(',')
          end
        end
      end
      debug_log("%s='%s'" % ['scaleio_mdm_ips_from_gateway', result])
      result
    end
  end
end
