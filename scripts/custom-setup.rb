# module1.rb
module CustomSetup
  
  def self.getValues( scenario, scenarioPath = nil )
    
    scenarioConfig = scenario["config"];
    
    # Check custom values for provision
    customFilePath = File.join(File.dirname(__FILE__),'..', '..', 'setup', scenario["name"] +"_v"+scenario["version"]+"_conf.json")
    if File.exist?(customFilePath) then
      
      out = JSON.parse(File.read(customFilePath))
      out["servers"].zip(scenarioConfig["servers"]).each do |o2s, o1s|
        o1s.each do |key, value|
          if o2s[key] == nil then
            o2s[key] = o1s[key]
          end
        end   
      end  
      
      # Write custom config to scenario.json
      if scenarioPath then
        scenario["config"] = out
        File.open(File.join(scenarioPath, 'scenario.json'),"w") do |f|
          f.write(scenario.to_json)
        end
      end

    else 
      out = scenarioConfig
    end

    return out   
  end
  
  def self.isFreeDiskSpace( scenario )
    if scenario["diskspaceGb"] then
      if File.exists?('C:\\') then
        # Windows
        gb_available = `dir /-C`.match(/(\d+) bytes free/).captures[0].to_i/1024/1024/1024
      else
        # Unix
        gb_available = `df .`.match(/(\d+)\s*\d*%/).captures[0].to_i*512/1024/1024/1024
      end		
      return gb_available > scenario["diskspaceGb"]
    else
      return true
    end
  end
end
