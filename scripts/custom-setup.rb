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
end
