require 'chef/provisioning/driver'

class DummyDriver < Chef::Provisioning::Driver
  def self.from_url(url, config)
    DummyDriver.new(url, config)
  end

  def initialize(url, config)
    super(url, config)
  end

  def cloud_url
    scheme, cloud_url = url.split(':', 2)
    cloud_url
  end

  def the_ultimate_cloud
    TheUltimateCloud.connect(cloud_url, driver_config['username'], driver_config['password'])
  end
end
