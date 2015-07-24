#!/usr/bin/env chef-apply

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

# -----------------------------------------
# driver_init/
directory prefix("driver_init") do
  recursive true
end

# -----------------------------------------
# driver_init/dummy.rb
file prefix("driver_init/#{snake_name}.rb") do
  content <<-EOS
require 'chef/provisioning/#{snake_driver}/driver'
Chef::Provisioning.register_driver_class('#{snake_name}', Chef::Provisioning::#{camel_name}Driver::Driver)
  EOS
end

# -----------------------------------------
# dummy_driver.rb
file prefix("#{snake_driver}.rb") do
  content <<-EOS
require 'chef/provisioning'
require 'chef/provisioning/#{snake_driver}/driver'
  EOS
end

# -----------------------------------------
# dummy_driver/
directory prefix("#{snake_driver}") do
  recursive true
end

# -----------------------------------------
# dummy_driver/version.rb
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

# -----------------------------------------
# dummy_driver/driver.rb
file prefix("#{snake_driver}/driver.rb") do
  content <<-EOS
require 'chef/provisioning/driver'
require 'chef/provisioning/#{snake_driver}/version'

class Chef
module Provisioning
module #{camel_name}
  class Driver < Chef::Provisioning::Driver
  end
end
end
end
  EOS
end

# -----------------------------------------
execute "rspec --init && echo '-fd' >> .rspec" do
  cwd driver_dir
  not_if { File.exist?("spec") }
end

# -----------------------------------------
# spec/spec_helper.rb
file "spec/spec_helper.rb" do
  content <<-EOS
require '#{snake_name}_support'

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    # This option will default to `true` in RSpec 4. It makes the `description`
    # and `failure_message` of custom matchers include text for helper methods
    # defined using `chain`, e.g.:
    #     be_bigger_than(2).and_smaller_than(4).description
    #     # => "be bigger than 2 and smaller than 4"
    # ...rather than:
    #     # => "be bigger than 2"
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.filter_run :focus
  config.run_all_when_everything_filtered = true
end
  EOS
end

# -----------------------------------------
# spec/dummy_spec.rb
file "spec/#{snake_name}_spec.rb" do
  content <<-EOS
describe "Chef::Provisioning::#{camel_name}" do
  extend #{camel_name}Support
  include #{camel_name}Config

  when_the_chef_12_server "exists", server_scope: :context, port: 8900..9000 do
    # with_#{snake_name} "integration tests" do
      context "machine resource" do
        it "doesn't run any tests" do
        end
      end
    # end
  end
end
  EOS
end

# -----------------------------------------
# spec/dummy_support.rb
file "spec/#{snake_name}_support.rb" do
  content <<-EOS
module #{camel_name}Support
  require 'cheffish/rspec/chef_run_support'
  def self.extended(other)
    other.extend Cheffish::RSpec::ChefRunSupport
  end

  # needed?
  require 'chef/provisioning/fake_generated_driver'
  def with_#{snake_name}(description, *tags, &block)
    context_block = proc do
      #{snake_driver} = Chef::Provisioning.driver_for_url("#{snake_name}")

      @@driver = #{snake_driver}
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

# -----------------------------------------
file "Gemfile" do
  content <<-EOS
source "https://rubygems.org"
gem "chef", ">= 12.4.1"
gem "cheffish"
gem "chef-provisioning"
  EOS
end

# -----------------------------------------
log "If you'd like to package this as a gem, start with the following command: 'cd .. && bundle gem chef-provisioning-#{driver_name}'" do
  not_if { File.exist?("chef-provisioning-#{driver_name}.gemspec") }
end
