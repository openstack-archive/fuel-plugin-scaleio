require 'date'
require 'facter'
require 'json'

$scaleio_log_file = "/var/log/fuel-plugin-scaleio.log"
def debug_log(msg)  
  File.open($scaleio_log_file, 'a') {|f| f.write("%s: %s\n" % [Time.now.strftime("%Y-%m-%d %H:%M:%S"), msg]) }
end


$astute_config = '/etc/astute.yaml'
if File.exists?($astute_config)
  Facter.add(:scaleio_sds_config) do
    setcode do
      result = nil
      config = YAML.load_file($astute_config)
      if config and config.key('fuel_version') and config.key('fuel_version') > '8.0'
        galera_host = config['management_vip']
        mysql_opts = config['mysql']
        password = mysql_opts['root_password']
        sql_query = "mysql -h %s -uroot -p%s -e 'USE scaleio; SELECT * FROM sds \\G;' 2>>%s | awk '/value:/ {sub($1 FS,\"\" );print}'" % [galera_host, password, $scaleio_log_file]
        debug_log(sql_query)
        query_result = Facter::Util::Resolution.exec(sql_query)
        debug_log(query_result)
        if query_result
          query_result.each_line do |r|
            if r
              if not result
                result = '{'
              else
                result += ', '
              end
              result += r.strip.slice(1..-2)
            end
          end
          result += '}' unless !result
        end        
      end
      debug_log("scaleio_sds_config='%s'" % result)
      result
    end
  end
end
