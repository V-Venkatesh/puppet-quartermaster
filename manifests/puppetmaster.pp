#Class: quartermaster::puppetmaster
#
# Installs and configures a puppetmaster and puppetdb on the quartermaster server
#
# Parameters: none
#
# Actions:
#
# Requires: see Modulefile
#
# }
#

class quartermaster::puppetmaster () inherits quartermaster::params {

  class {'puppetdb':}
  class {'puppet::master':
    autosign     => true,
    storeconfigs => true,
    parser       => 'future',
    environments => 'directory',
  } 
  file  {'/etc/puppet/files':
    ensure => directory,
    require => Class['puppet::master'],
  }

  file {'/etc/puppet/fileserver.conf':
    ensure  => file,
    require => Class['puppet::master'],
    source  => "puppet:///modules/quartermaster/puppetmaster/fileserver.conf",
    notify  => Service['apache2'],
  }

}
