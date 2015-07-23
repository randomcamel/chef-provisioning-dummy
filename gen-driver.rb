#!/usr/bin/env chef-apply


# ├── Gemfile
# ├── Gemfile.lock
# ├── chef-provisioning-dummy.gemspec
# ├── lib
# │   └── chef
# │       └── provisioning
# │           ├── driver_init
# │           │   └── dummy.rb
# │           ├── dummy_driver
# │           │   ├── driver.rb
# │           │   └── version.rb
# │           └── dummy_driver.rb
# └── spec
#     ├── dummy_spec.rb
#     ├── dummy_support.rb
#     └── spec_helper.rb

driver_name = ARGV[1]
snake_name = driver_name.downcase.gsub('-', '_')
snake_driver = "#{snake_name}_driver"
driver_dir = "#{ENV['PWD']}/chef-provisioning-#{driver_name}"

camel_name = snake_name.split(/[_-]/).collect(&:capitalize).join

# gross.
`mkdir #{driver_dir}`
Dir.chdir driver_dir

def prefix(subpath)
  "lib/chef/provisioning/#{subpath}"
end

# driver_init/
directory prefix("driver_init") do
  recursive true
end

file prefix("driver_init/#{snake_name}.rb") do
  content <<-EOS
require 'chef/provisioning/#{snake_driver}/driver'
ChefMetal.register_driver_class('#{snake_name}', Chef::Provisioning::#{camel_name}Driver::Driver)
  EOS
end

file prefix("#{snake_driver}.rb") do
  content <<-EOS
require 'chef/provisioning'
require 'chef/provisioning/#{snake_driver}/driver'
  EOS
end

# #{driver_name}_driver/
directory prefix("#{snake_driver}") do
  recursive true
end

file prefix("#{snake_driver}/version.rb") do
  content <<-EOS
class Chef
module Provisioning
module #{camel_name}Driver
  VERSION = '0.1'
end
end
end
EOS
end

file prefix("#{snake_driver}/driver.rb")

execute "rspec --init && echo '-fd' >> .rspec" do
  cwd driver_dir
  not_if { File.exist?("spec") }
end

file "spec/#{snake_name}_spec.rb" do
  content <<-EOS
describe "Chef::Provisioning::#{camel_name}" do
  extend #{camel_name}Support
  include #{camel_name}Config

  when_the_chef_12_server "exists", server_scope: :context, port: 8900..9000 do
    with_dummy "integration tests" do
      context "machine resource" do
        it "runs :create by default" do
          expect_recipe {
            machine "fake-machine"
          }
        end
      end
    end
  end
end
  EOS
end

file "spec/#{snake_name}_support.rb" do
  content <<-EOS
module #{camel_name}Support
  require 'cheffish/rspec/chef_run_support'
  def self.extended(other)
    other.extend Cheffish::RSpec::ChefRunSupport
  end

  def with_dummy(description, *tags, &block)
    context_block = proc do
      #{snake_name}_driver = Chef::Provisioning.driver_for_url("#{snake_name}")

      @@driver = #{snake_name}_driver
      def self.driver
        @@driver
      end

      module_eval(&block)
    end

    when_the_repository "exists and \#{description}", *tags, &context_block
  end
end

module #{camel_name}Config
  def chef_config
    @chef_config ||= {
      driver:       Chef::Provisioning.driver_for_url("#{snake_name}"),
    }
  end
end
EOS
end

log "If you'd like to package this as a gem, start with the following command: 'cd .. && bundle gem chef-provisioning-#{driver_name}'" do
  not_if { File.exist?("chef-provisioning-#{driver_name}.gemspec") }
end
