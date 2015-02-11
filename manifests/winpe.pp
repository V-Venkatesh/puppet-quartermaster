# Class: quartermaster::winpe
#
# This Class installs and configures services to support
# deploying Windows Unattended via Pxe.
# A Samba share is created for ISO placement.
# ISO put in that directory will be automated and exported via
# Samba and Apache
#
class quartermaster::winpe (
  $tmp            = $quartermaster::params::tmp,
  $pxeroot        = $quartermaster::params::pxeroot,
  $pxecfg         = $quartermaster::params::pxecfg,
  $pxe_menu       = $quartermaster::params::pxe_menu,
  $tftpboot       = $quartermaster::params::tftpboot,
  $tftp_username  = $quartermaster::params::tftp_username,
  $tftp_group     = $quartermaster::params::tftp_group,
  $tftp_filemode  = $quartermaster::params::tftp_filemode,
  $wwwroot        = $quartermaster::params::wwwroot,
  $www_username   = $quartermaster::params::www_username,
  $www_group      = $quartermaster::params::www_group,
  $file_mode      = $quartermaster::params::file_mode,
  $dir_mode       = $quartermaster::params::dir_mode,
  $exe_mode       = $quartermaster::params::exe_mode,
  $os             = $quartermaster::params::os,
  $windows_isos   = $quartermaster::params::windows_isos,

) inherits params {


# Install WimLib
  case $osfamily {
    'Debian':{
      apt::ppa{'ppa:nilarimogard/webupd8':}
      $wimtool_repo = Apt::Ppa['ppa:nilarimogard/webupd8'] 
    }

    'RedHat':{
      yumrepo{'Nux Misc':
        name     => 'nux-misc',
        baseurl  => 'http://li.nux.ro/download/nux/misc/el6/x86_64/',
        enabled  => '0',
        gpgcheck => '1',
        gpgkey   => 'http://li.nux.ro/download/nux/RPM-GPG-KEY-nux.ro',
      }
      $wimtool_repo = Yumrepo['Nux Misc']
    }

    default:{
      warn('Currently Unsupported OSFamily for this feature')
    }
  }

  package { 'wimtools':
    ensure  => latest,
    require => $wimtool_repo,
  }



# Add Winpe directory to TFTPBOOT and entry to PXE menu
  tftp::file{'winpe':
    ensure  => directory,
  }

  concat::fragment{"winpe_pxe_default_menu":
    target  => "${pxecfg}/default",
    content => template("quartermaster/pxemenu/winpe.erb"),
    require => Tftp::File['pxelinux/pxelinux.cfg']
  }

# Samba Services for Hosing Windows Shares


  file{[
    "${wwwroot}/microsoft",
    "${wwwroot}/microsoft/iso",
    "${wwwroot}/microsoft/mount",
    "${wwwroot}/microsoft/winpe",
    "${wwwroot}/microsoft/winpe/bin",
    "${wwwroot}/microsoft/winpe/system",
    "${wwwroot}/microsoft/winpe/system/menu",
    ]:
    ensure => directory,
  }

  class{'::samba::server':
    workgroup            => 'PXE',
    netbios_name         => "${::hostname}",
    security             => 'user',
    map_to_guest         => 'Bad User',
    guest_account        => 'nobody',
    extra_global_options => [
      'wide links    = yes',
      'unix extensions = no',
      'follow symlins = yes',
      'kernel oplocks = no',
      'guest ok = yes',
    ],
    shares => {
      'installs' => [
        "path = ${wwwroot}",
        'read only = yes',
        'guest ok = yes',
        'fake oplocks = true',
      ],
      'IPC$' => [
        "path = /etc/samba/fakeIPC",
        'read only = yes',
        'guest ok = yes',
        'valid users = nobody',
      ],
      'os' => [
        "path = ${wwwroot}/microsoft",
        'read only = yes',
        'guest ok = yes',
        'fake oplocks = true',
      ],
      'ISO' => [
        "path = ${wwwroot}/microsoft/iso",
        'read only = no',
        'guest ok = yes',
      ],
      'winpe' => [
        "path = ${wwwroot}/microsoft/winpe",
        'read only = no',
        'guest ok = yes',
      ],
      'system' => [
        "path = ${wwwroot}/microsoft/winpe/system",
        'read only = no',
        'guest ok = yes',
      ],
      'pxe-cfg' => [
        "path = ${tftpboot}/pxelinux/pxelinux.cfg",
        'read only = no',
        'guest ok = yes',
      ],
     'pe-pxeroot' => [
        "path = ${tftpboot}/winpe",
        'read only = no',
        'guest ok = yes',
      ],

    },

  }

#Autofs For Automouting Windows iso's
  autofs::mount{ "${wwwroot}/microsoft/mount":
    map     => '/etc/auto.quartermaster',
    options => ['--timeout=10', ],
  }
  autofs::mount{ '*':
    map     => ":${wwwroot}/microsoft/iso/&",
    options => [
      '-fstype=iso9660,loop',
    ],
    mapfile => '/etc/auto.quartermaster',
  }
  file_line {'udf_iso_automation':
    path    => '/etc/auto.quartermaster',
    line    => "* -fstype=udf,loop :${wwwroot}/microsoft/iso/&",
    require => Autofs::Mount['*'],
    notify  => Service['autofs'],
  }



  # Add Winpe to the PXE menu

  # Begin Windows provisioning Scripts

  file { "${wwwroot}/microsoft/winpe/system/init.cmd":
    ensure  => file,
    mode    => $exe_mode,
    content => template('quartermaster/winpe/menu/init.erb'),
    require => File["${wwwroot}/microsoft/winpe/system"],
  }
  file { "${wwwroot}/microsoft/winpe/system/menucheck.ps1":
    ensure  => file,
    mode    => $exe_mode,
    content => template('quartermaster/winpe/menu/menucheckps1.erb'),
    require => File["${wwwroot}/microsoft/winpe/system"],
  }
  file { "${wwwroot}/microsoft/winpe/system/puppet_log.ps1":
    ensure  => file,
    mode    => $exe_mode,
    content => template('quartermaster/scripts/puppet_log.ps1.erb'),
    require => File["${wwwroot}/microsoft/winpe/system"],
  }
  file { "${wwwroot}/microsoft/winpe/system/firstboot.cmd":
    ensure  => file,
    mode    => $exe_mode,
    content => template('quartermaster/scripts/firstbootcmd.erb'),
    require => File["${wwwroot}/microsoft/winpe/system"],
  }
  file { "${wwwroot}/microsoft/winpe/system/secondboot.cmd":
    ensure  => file,
    mode    => $exe_mode,
    content => template('quartermaster/scripts/secondbootcmd.erb'),
    require => File["${wwwroot}/microsoft/winpe/system"],
  }
  file { "${wwwroot}/microsoft/winpe/system/compute.cmd":
    ensure  => file,
    mode    => $exe_mode,
    content => template('quartermaster/scripts/computecmd.erb'),
    require => File["${wwwroot}/microsoft/winpe/system"],
  }
  file { "${wwwroot}/microsoft/winpe/system/puppetinit.cmd":
    ensure  => file,
    mode    => $exe_mode,
    content => template('quartermaster/scripts/puppetinitcmd.erb'),
    require => File["${wwwroot}/microsoft/winpe/system"],
  }
  file { "${wwwroot}/microsoft/winpe/system/rename.ps1":
    ensure  => file,
    mode    => $exe_mode,
    content => template('quartermaster/scripts/rename.ps1.erb'),
    require => File["${wwwroot}/microsoft/winpe/system"],
  }

#Begin Winpe menu
  concat { "${wwwroot}/microsoft/winpe/system/setup.cmd":
    mode    => $exe_mode,
  }
  concat::fragment{"winpe_system_cmd_a00_header":
    target  => "${wwwroot}/microsoft/winpe/system/setup.cmd",
    content => template('quartermaster/winpe/menu/A00_init.erb'),
    order   => 01,
  }
  concat::fragment{"winpe_system_cmd_b00_init":
    target  => "${wwwroot}/microsoft/winpe/system/setup.cmd",
    content => template('quartermaster/winpe/menu/B00_init.erb'),
    order   => 10,
  }
  concat::fragment{"winpe_system_cmd_c00_init":
    target  => "${wwwroot}/microsoft/winpe/system/setup.cmd",
    content => template('quartermaster/winpe/menu/C00_init.erb'),
    order   => 20,
  }
  concat::fragment{"winpe_menu_footer":
    target  => "${wwwroot}/microsoft/winpe/system/setup.cmd",
    content => template('quartermaster/winpe/menu/D00_init.erb'),
    order   => 99,
  }

}
