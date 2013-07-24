# This Puppetfile generates a working Quartermaster for generating all necessary images.
#
# Git Settings
git_protocol=ENV['git_protocol'] || 'git'
base_url = "#{git_protocol}://github.com"

# 
branch_name = 'origin/grizzly'
mod 'puppetlabs/postgresql', :git => "#{base_url}/puppetlabs/puppetlabs-postgresql", :ref => 'master'
mod 'puppetlabs/puppetdb', :git => "#{base_url}/puppetlabs/puppetlabs-puppetdb", :ref => 'master'
mod 'puppetlabs/firewall', :git => "#{base_url}/puppetlabs/puppetlabs-firewall", :ref => 'master'
mod 'puppetlabs/ntp', :git => "#{base_url}/puppetlabs/puppetlabs-ntp", :ref => 'master'

# stephenrjohnson
# this what I am testing Puppet 3.2 deploys with
# I am pointing it at me until my patch is accepted
mod 'stephenjohrnson/puppet', :git => "#{base_url}/stephenrjohnson/puppetlabs-puppet", :ref => 'master'

mod 'CiscoSystems/apt', :git => "#{base_url}/CiscoSystems/puppet-apt", :ref => branch_name
mod 'CiscoSystems/stdlib', :git => "#{base_url}/CiscoSystems/puppet-stdlib", :ref => branch_name
mod 'CiscoSystems/mysql', :git => "#{base_url}/CiscoSystems/puppet-mysql", :ref => branch_name
#mod 'CiscoSystems/apache', :git => "#{base_url}/CiscoSystems/puppet-apache", :ref => branch_name


# upstream is ripienaar
#mod 'ripienaar/concat', :git => "#{base_url}/CiscoSystems/puppet-concat", :ref => branch_name
mod 'ripienaar/concat', :git => "#{base_url}/CiscoSystems/puppet-concat", :ref => 'origin/grizzly'

# upstream is cprice-puppet/puppetlabs-inifile
#mod 'CiscoSystems/inifile', :git => "#{base_url}/CiscoSystems/puppet-inifile"
mod 'cprice404/inifile', :git => "#{base_url}/cprice-puppet/puppetlabs-inifile"
# Removed ref due to confilt
#, :ref => branch_name

mod 'ppouliot/quartermaster', :git => "#{base_url}/ppouliot/puppet-quartermaster"
mod 'ppouliot/apache', :git => "#{base_url}/ppouliot/puppet-apache", :ref => branch_name
