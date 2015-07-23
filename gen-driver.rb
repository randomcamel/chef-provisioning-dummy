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
driver_dir = "chef-provisioning-#{underscore_name.gsub('-', '-')}"

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


execute "rspec --init && echo '-fd' >> .rspec"

%w{spec support}.each do |f|
  file "spec/#{underscore_name}_#{f}.rb"
end