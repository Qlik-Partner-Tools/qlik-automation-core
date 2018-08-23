# module1.rb
module CustomSetup
  def self.getValues( scenario )
  # Check custom values for provision
  	out = scenario["config"];
    customFilePath = File.join(File.dirname(__FILE__),'..', '..', 'setup', scenario["name"] +"_conf.json")
    if File.exist?(customFilePath) then
        out = JSON.parse(File.read(customFilePath))
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
