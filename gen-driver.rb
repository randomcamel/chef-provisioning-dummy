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

underscore_name = ARGV[1].downcase
underscore_driver = "#{underscore_name}_driver"
driver_dir = "#{ENV['PWD']}/chef-provisioning-#{underscore_name.gsub('-', '-')}"

camel_name = underscore_name.split('_').collect(&:capitalize).join

# gross.
`mkdir #{driver_dir}`
Dir.chdir driver_dir

def prefix(subpath)
  "lib/chef/provisioning/#{subpath}"
end

["driver_init", "#{underscore_name}_driver"].each do |dir|
  directory prefix(dir) do
    recursive true
  end
end

file prefix("#{underscore_driver}.rb") do
  content <<-EOS
  require 'chef/provisioning'
  require 'chef/provisioning/#{underscore_driver}/driver'
  EOS
end

file prefix("#{underscore_driver}/version.rb") do
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

file prefix("#{underscore_driver}/driver.rb")

execute "rspec --init && echo '-fd' >> .rspec" do
  cwd driver_dir
  not_if { File.exist?("spec") }
end

file "spec/#{underscore_name}_spec.rb"

file "spec/#{underscore_name}_support.rb" do
  content <<-EOS
module #{camel_name}Support
  require 'cheffish/rspec/chef_run_support'
  def self.extended(other)
    other.extend Cheffish::RSpec::ChefRunSupport
  end

  def with_dummy(description, *tags, &block)
    context_block = proc do
      #{underscore_name}_driver = Chef::Provisioning.driver_for_url("#{underscore_name}")

      @@driver = #{underscore_name}_driver
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
      driver:       Chef::Provisioning.driver_for_url("#{underscore_name}"),
    }
  end
end
EOS
end
