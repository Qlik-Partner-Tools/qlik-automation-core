# module1.rb
module CustomSetup
  def self.getValues( scenario )
  # Check custom values for provision
  	out = scenario["config"];
    customFilePath = File.join(File.dirname(__FILE__),'..', '..', 'setup', scenario["name"] +"_conf.json")
    if File.exist?(customFilePath) then
      out2 = JSON.parse(File.read(customFilePath))
      out2["servers"].zip(out["servers"]).each do |o2s, o1s|
        o1s.each do |key, value|
          if o2s[key] == nil then
            o2s[key] = o1s[key]
          end
        end   
      end  
      return out2
    else
      return out
    end  
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
