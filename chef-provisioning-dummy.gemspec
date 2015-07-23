$:.unshift(File.dirname(__FILE__) + '/lib')
# require 'chef/provisioning/version'

Gem::Specification.new do |s|
  s.name = 'chef-provisioning-dummy'
  s.version = "0.1"
  s.platform = Gem::Platform::RUBY
  # s.extra_rdoc_files = ['README.md', 'CHANGELOG.md', 'LICENSE' ]
  s.summary = 'A dummy driver for testing chef-provisioning.'
  s.description = s.summary
  s.author = 'Chris Doherty'
  s.email = 'cdoherty@chef.io'
  s.homepage = 'http://github.com/chef/chef-provisioning/README.md'

  s.add_dependency 'chef', '>= 11.16.4'
  s.add_dependency 'chef-provisioning', '~> 1.1'
  # s.add_dependency 'net-ssh', '~> 2.0'
  # s.add_dependency 'net-scp', '~> 1.0'
  # s.add_dependency 'net-ssh-gateway', '~> 1.2.0'
  s.add_dependency 'inifile', '~> 2.0'
  s.add_dependency 'cheffish', '~> 1.1'
  s.add_dependency 'winrm', '~> 1.3'

  s.add_development_dependency 'rspec'
  s.add_development_dependency 'rake'
  s.add_development_dependency 'pry'

  s.bindir       = "bin"
  s.executables  = %w( )

  s.require_path = 'lib'
  s.files = %w(Rakefile LICENSE README.md CHANGELOG.md) + Dir.glob("{distro,lib,tasks,spec}/**/*", File::FNM_DOTMATCH).reject {|f| File.directory?(f) }
end
