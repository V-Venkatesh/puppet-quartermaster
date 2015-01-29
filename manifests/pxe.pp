# Class: quartermaster::pxe
#
# This Class defines the creation of the linux pxe infrastructure
#


define quartermaster::pxe {

  $tmp            = $quartermaster::params::tmp
  $pxeroot        = $quartermaster::params::pxeroot
  $pxecfg         = $quartermaster::params::pxecfg
  $pxe_menu       = $quartermaster::params::pxe_menu
  $tftpboot       = $quartermaster::params::tftpboot
  $tftp_username  = $quartermaster::params::tftp_username
  $tftp_group     = $quartermaster::params::tftp_group
  $tftp_filemode  = $quartermaster::params::tftp_filemode
  $wwwroot        = $quartermaster::params::wwwroot
  $www_username   = $quartermaster::params::www_username
  $www_group      = $quartermaster::params::www_group
  $file_mode      = $quartermaster::params::file_mode



# account for "."
  if $name =~ /([a-zA-Z0-9_\.]+)-([a-zA-Z0-9_\.]+)-([a-zA-Z0-9_\.]+)/ {
# works w/ no .
#if $name =~ /([a-zA-Z0-9_]+)-([a-zA-Z0-9_]+)-([a-zA-Z0-9_]+)/ {
    $distro  = $1
#    $rel_number = regsubst($2, '(\.)','','G')
    $release = $2
    $p_arch  = $3
  }

  $rel_number = regsubst($release, '(\.)','','G')

  if $release =~/([0-9]+).([0-9])/{
    $rel_major = $1
    $rel_minor = $2
  }


  case $distro {

    'centos':{
      $supported_endpoint = '7'
      $archived_endpoint  = '6.6'
      if $release <= $archived_endpoint {
        $use_archive = 'true'
      }
      if $release >= $supported_endpoint {
        $use_archive = 'false'
      }

      $centos_url = $use_archive ? {
        /(true)/   => "http://vault.centos.org/${release}",
        /(false)/  => "http://mirror.centos.org/centos/${rel_major}",
      }

      if ( $release >= '7.0' ) and ( $p_arch == 'i386'){
        fail("Centos ${release} does not provide support for processor architecture i386")
      }
    }
    'fedora':{
      $supported_endpoint = '20'
      $archived_endpoint  = '19'
      if $release <= $archived_endpoint {
        $use_archive = 'true'
      }
      if $release >= $supported_endpoint {
        $use_archive = 'false'
      }

      $fedora_url = $use_archive ? {
        /(true)/   => 'http://archives.fedoraproject.org/pub/archive',
        /(false)/  => 'http://dl.fedoraproject.org/pub',
      }

      if $release >= '21' {
        $flavor = ['Workstation','Server']
        $pxe_flavor = ['W','S']
      }
      if $release < '21' {
        $flavor = ['Fedora',]
        $pxe_flavor = []
      }
    }
    'opensuse':{
      $supported_endpoint = '12.3'
      $archived_endpoint  = '12.2'
      if $release <= $archived_endpoint {
        $use_archive = 'true'
      }
      if $release >= $supported_endpoint {
        $use_archive = 'false'
      }
      $opensuse_url = $use_archive ? {
        /(true)/   => "http://ftp5.gwdg.de/pub/opensuse/discontinued/distribution",
        /(false)/  => "http://download.opensuse.org/distribution",
      }
    }
    default:{
      $use_archive        = undef
      $archived_endpoint  = '0'
      $supported_endpoint = $release
    }
  }

  # Begin tests for dealing with OracleLinux Repos
  $is_oracle = $distro ? {
    /(oraclelinux)/ => 'true',
    default         => 'This is not Oracle Linux',  
  }

  $rel_name = $release ? {
    /(11.04)/     => 'natty',
    /(11.10)/     => 'oneric',
    /(12.04)/     => 'precise',
    /(12.10)/     => 'quantal',
    /(13.04)/     => 'raring',
    /(13.10)/     => 'saucy',
    /(14.04)/     => 'trusty',
    /(14.10)/     => 'utopic',
    /(15.04)/     => 'vivid',
    /(oldstable)/ => 'squeeze',
    /(stable)/    => 'wheezy',
    /(testing)/   => 'jessie',
    /(unstable)/  => 'sid',
    default      => "Unsupported ${distro} Release",
  }

  $url = $distro ? {
    /(ubuntu)/          => "http://archive.ubuntu.com/${distro}/dists/${rel_name}/main/installer-${p_arch}/current/images/netboot/${distro}-installer/${p_arch}",
    /(debian)/          => "http://ftp.debian.org/${distro}/dists/${rel_name}/main/installer-${p_arch}/current/images/netboot/${distro}-installer/${p_arch}",
#    /(ubuntu|debian)/   => "http://${webhost}.${distro}.${tld}/${distro}/dists/${rel_name}/main/installer-${p_arch}/current/images/netboot/${distro}-installer/${p_arch}",
    /(centos)/          => "${centos_url}/os/${p_arch}/images/pxeboot",
#    /(fedora)/          => "http://dl.fedoraproject.org/pub/${distro}/linux/releases/${release}/Fedora/${p_arch}/os/images/pxeboot",
#    /(fedora)/          => "http://archives.fedoraproject.org/pub/${distro}/linux/releases/${release}/Fedora/${p_arch}/os/images/pxeboot",
    /(fedora)/          => "${fedora_url}/${distro}/linux/releases/${release}/${flavor}/${p_arch}/os/images/pxeboot",
    /(scientificlinux)/  => "http://ftp.scientificlinux.org/linux/scientific/${release}/${p_arch}/os/images/pxeboot",
    /(oraclelinux)/     => "Enterprise ISO Required",
    /(redhat)/          => 'Enterprise ISO Required',
    /(sles)/            => 'Enterprise ISO Required',
    /(sled)/            => 'Enterprise ISO Required',
    /(opensuse)/        => "${opensuse_url}/${release}/repo/oss/boot/${p_arch}/loader",
    default             => 'No URL Specified',
  }

  $tld = $distro ?{
    /(ubuntu)/ => 'com',
    /(debian)/ => 'org',
    default    => "tld isn't needed for ${distro}",   
  }
  $webhost = $distro ?{
    /(ubuntu)/ => 'archive',
    /(debian)/ => 'ftp.us',
    default    => "webhost isn't needed for ${distro}",   
  }


  $inst_repo = $distro ? {
    /(ubuntu)/          => "http://archive.ubuntu.com/${distro}/dists/${rel_name}",
    /(debian)/          => "http://ftp.debian.org/${distro}/dists/${rel_name}",
    /(centos)/          => "${centos_url}/os/${p_arch}/",
    /(fedora)/          => "${fedora_url}/${distro}/linux/releases/${release}/${flavor}/${p_arch}/os",
    /(scientificlinux)/ => "http://ftp.scientificlinux.org/linux/scientific/${release}/${p_arch}/os",
    /(oraclelinux)/     => "http://public-yum.oracle.com/repo/OracleLinux/OL${rel_major}/${rel_minor}/base/${p_arch}/",
    /(redhat)/          => 'Enterprise ISO Required',
    /(sles)/            => 'Enterprise ISO Required',
    /(sled)/            => 'Enterprise ISO Required',
    /(opensuse)/        => "http://download.opensuse.org/distribution/${release}/repo/oss/boot/${p_arch}/loader",
    default             => 'No URL Specified',
  }

  $update_repo = $distro ? {
    /(ubuntu)/          => "http://archive.ubuntu.com/${distro}/dists/${rel_name}",
    /(debian)/          => "http://ftp.debian.org/${distro}/dists/${rel_name}",
    /(centos)/          => "${centos_url}/updates/${p_arch}/",
    /(fedora)/          => "${fedora_url}/${distro}/linux/releases/${release}/${flavor}/${p_arch}/os",
    /(scientificlinux)/ => "http://ftp.scientificlinux.org/linux/scientific/${release}/${p_arch}/updates/security",
    /(oraclelinux)/     => "http://public-yum.oracle.com/repo/OracleLinux/OL${rel_major}/${rel_minor}/base/${p_arch}/",
    /(redhat)/          => 'Enterprise ISO Required',
    /(sles)/            => 'Enterprise ISO Required',
    /(sled)/            => 'Enterprise ISO Required',
    /(opensuse)/        => "http://download.opensuse.org/distribution/${release}/repo/non-oss/suse",
    default             => 'No URL Specified',
  }

  $splashurl = $distro ? {
    /(ubuntu)/         => "http://archive.ubuntu.com/${distro}/dists/${rel_name}/main/installer-${p_arch}/current/images/netboot/${distro}-installer/${p_arch}/boot-screens/splash.png",
    /(debian)/         => "http://ftp.debian.org/${distro}/dists/${rel_name}/main/installer-${p_arch}/current/images/netboot/${distro}-installer/${p_arch}/boot-screens/splash.png",
    /(redhat)/          => 'Enterprise ISO Required',
    /(centos)/          => "${centos_url}/os/${p_arch}/isolinux/splash.jpg",
    /(fedora)/          => "${fedora_url}/${distro}/linux/releases/${release}/${flavor}/${p_arch}/os/isolinux/splash.png",
    /(scientificlinux)/ => "http://ftp.scientificlinux.org/linux/scientific/${release}/${p_arch}/os/isolinux/splash.jpg",
    /(oraclelinux)/     => "http://public-yum.oracle.com/repo/OracleLinux/OL${rel_major}/${rel_minor}/base/${p_arch}/",
    /(sles)/            => 'Enterprise ISO Required',
    /(sled)/            => 'Enterprise ISO Required',
    /(opensuse)/        => "http://download.opensuse.org/distribution/${release}/repo/oss/boot/${p_arch}/loader/back.jpg",
    default             => 'No URL Specified',
  }

  $bootsplash = $distro ? {
    /(ubuntu|debian|fedora|scientificlinux)/             => '.png',
    /(redhat|centos|opensuse|sles|sled)/                 => '.jpg',
    /(windows)/                                          => 'No Bootsplash',
    /(oraclelinux)/                                      => 'No Bootsplash ',
    default                                              => 'No Bootsplash',
  }

  $autofile = $distro ? {
    /(ubuntu|debian)/                                    => 'preseed',
    /(redhat|centos|fedora|scientificlinux|oraclelinux)/ => 'kickstart',
    /(sles|sled|opensuse)/                               => 'autoyast',
    /(windows)/                                          => 'unattend.xml',
    default                                              => 'No Automation File',
  }

  $pxekernel = $distro ? {
    /(ubuntu|debian)/                                    => 'linux',
    /(redhat|centos|fedora|scientificlinux|oraclelinux)/ => 'vmlinuz',
    /(sles|sled|opensuse)/                               => 'linux',
    default                                              => 'No supported Pxe Kernel',
  }

  $initrd = $distro ? {
    /(ubuntu|debian)/                                    => '.gz',
    /(redhat|centos|fedora|scientificlinux|oraclelinux)/ => '.img',
    /(sles|sled|opensuse)/                               => undef,
    default                                              => 'No supported Initrd Extension',
  }

  $target_initrd = $distro ? {
    /(sles|sled|opensuse)/                               => '${rel_number}.gz',
    /(fedora)/                                           => "${rel_number}${pxe_flavor}${initrd}",
    default                                              => "${rel_number}${initrd}",
  }
  $target_kernel = $distro ? {
    /(fedora)/                                           => "${rel_number}${pxe_flavor}",
    default                                              => $rel_number,
  }

  $linux_installer = $distro ? {
    /(ubuntu|debian)/                                    => 'd-i',
    /(redhat|centos|fedora|scientificlinux|oraclelinux)/ => 'anaconda',
    /(sles|sled|opensuse)/                               => 'yast',
    default                                              => 'No Supported Linux Installer',
  }

  $puppetlabs_repo = $distro ? {
    /(ubuntu|debian)/                                    => "http://apt.puppetlabs.com/dists/${rel_name}",
    /(fedora)/                                           => "http://yum.puppetlabs.com/fedora/f${rel_number}/products/${p_arch}",
    /(redhat|centos|scientificlinux|oraclelinux)/        => "http://yum.puppetlabs.com/el/${rel_major}/products/${p_arch}",
    default                                              => 'No PuppetLabs Repo',
  }

  notify { "${name}: distro is ${distro}":}
  notify { "${name}: release is ${release}":}
  notify { "${name}: rel_major is ${rel_major}":}
  notify { "${name}: rel_minor is ${rel_minor}":}
  notify { "${name}: p_arch is  ${p_arch}":}
  notify { "${name}: url is ${url}":}
  notify { "${name}: inst_repo is ${inst_repo}":}
  notify { "${name}: kernel is ${pxekernel}":}
  notify { "${name}: initrd is ${initrd}":}
  notify { "${name}: linux_installer is ${linux_installer}":}
  notify { "${name}: PuppetLabs Repo is ${puppetlabs_repo}":}
  notify { "${name}: Centos Distro = ${is_centos}":}
  notify { "${name}: Centos Legacy = ${centos_legacy}":}
  notify { "${name}: Centos URL = ${centos_url}":}
  notify { "${name}: Fedora Distro = ${is_fedora}":}
  notify { "${name}: Fedora Legacy = ${fedora_legacy}":}
  notify { "${name}: Fedora URL = ${fedora_url}":}
  notify { "${name}: Oracle Distro = ${is_oracle}":}
  notify { "${name}: Target Initrd = ${target_initrd}":}

# Retrieve installation kernel file if supported
#  if $pxekernel == !('No supported Pxe Kernel'){
    if ! defined (Staging::File["kernel-${name}"]){
      staging::file{"kernel-${name}":
        source => "${url}/${pxekernel}", 
        target => "${tftpboot}/${distro}/${p_arch}/${target_kernel}",
        require =>  Tftp::File["${distro}/${p_arch}"],
      }
    }
#  } 

# Retrieve initrd file if supported
#  if $initrd == !('No supported Initrd Extension'){
    if ! defined (Staging::File["initrd-${name}"]){
      staging::file{"initrd-${name}":
        source => "${url}/initrd${initrd}",
        target => "${tftpboot}/${distro}/${p_arch}/${target_initrd}",
        require =>  Tftp::File["${distro}/${p_arch}"],
      }
    }
#  }

# Retrieve Bootsplash file if present
  if $bootsplash == !('No Bootsplash'){
    if ! defined (Staging::File["bootsplash-${name}"]){
      staging::file{"bootsplash-${name}":
        source => $splashurl,
        target => "${tftpboot}/${distro}/graphics/${name}${bootsplash}",
        require =>  Tftp::File["${distro}/graphics"],
      }
    }
  }


# Distro Specific TFTP Folders

  if ! defined (Tftp::File[$distro]){
    tftp::file { $distro: 
      ensure  => directory,
    }
  }


  if ! defined (Tftp::File["${distro}/menu"]){
    tftp::file { "${distro}/menu":
      ensure  => directory,
    }
  }

  if ! defined (Tftp::File["${distro}/graphics"]){
    tftp::file { "${distro}/graphics":
      ensure  => directory,
    }
  }

  if ! defined (Tftp::File["${distro}/${p_arch}"]){
    tftp::file { "${distro}/${p_arch}":
      ensure  => directory,
    }
  }

# Distro Specific TFTP Graphics.conf 

if $linux_installer == !('No Supported Linux Installer') {
  tftp::file { "${distro}/menu/${name}.graphics.conf":
    content => template("quartermaster/pxemenu/${linux_installer}.graphics.erb"),
    require => Tftp::File["${distro}/menu"],
  }
}
# Begin Creating Distro Specific HTTP Folders

  if ! defined (File["${wwwroot}/${distro}"]) {
    file { "${wwwroot}/${distro}":
      ensure  => directory,
      require => File[ $wwwroot ],
    }
  }

  if ! defined (File["${wwwroot}/${distro}/${autofile}"]) {
    file { "${wwwroot}/${distro}/${autofile}":
      ensure  => directory,
      require => File[ "${wwwroot}/${distro}" ],
    }
  }

  if ! defined (File["${wwwroot}/${distro}/${p_arch}"]) {
    file { "${wwwroot}/${distro}/${p_arch}":
      ensure  => directory,
      require => File[ "${wwwroot}/${distro}" ],
    }
  }

  if ! defined (File["${wwwroot}/${distro}/ISO"]) {
    file { "${wwwroot}/${distro}/ISO":
      ensure  => directory,
      require => File[ "${wwwroot}/${distro}" ],
    }
  }
  if ! defined (File["${wwwroot}/${distro}/${p_arch}/.README.html"]) {
    file { "${wwwroot}/${distro}/${p_arch}/.README.html":
      ensure  => file,
      require => File[ "${wwwroot}/${distro}" ],
      content => template("quartermaster/README.html.erb"),
    }
  }

# Kickstart/Preseed File
if $autofile == !('No Automation File'){
  file { "${name}.${autofile}":
    ensure  => file,
    path    => "${wwwroot}/${distro}/${autofile}/${name}.${autofile}",
    content => template("quartermaster/autoinst/${autofile}.erb"),
    require => File[ "${wwwroot}/${distro}/${autofile}" ],
  }
}

  if ! defined (Concat::Fragment["${distro}.default_menu_entry"]) {
    concat::fragment { "${distro}.default_menu_entry":
      target  => "${pxecfg}/default",
      content => template("quartermaster/pxemenu/default.erb"),
      order   => 02,
    }
  }

  if ! defined (Concat["${tftpboot}/menu/${distro}.menu"]) {
    concat { "${tftpboot}/menu/${distro}.menu":
      mode    => $tftp_filemode,
#      require => Tftp::File['menu'],
    }
  }
  if ! defined (Concat::Fragment["${distro}.submenu_header"]) {
    concat::fragment {"${distro}.submenu_header":
      target  => "${tftpboot}/menu/${distro}.menu",
      content => template("quartermaster/pxemenu/header2.erb"),
      order   => 01,
    }
  }
  if $linux_installer == !('No Supported Linux Installer') {
  if ! defined (Concat::Fragment["${distro}${name}.menu_item"]) {
    concat::fragment {"${distro}.${name}.menu_item":
      target  => "${tftpboot}/menu/${distro}.menu",
      content => template("quartermaster/pxemenu/${linux_installer}.erb"),
    }
  }
}

  if $linux_installer == !('No Supported Linux Installer') {
    tftp::file { "${distro}/menu/${name}.menu":
      content => template("quartermaster/pxemenu/${linux_installer}.erb"),
    }
  }
}
