# Class: quartermaster::syslinux
#
# This Class retrieves and stages the Syslinux/Pxelinux files
# require for pxebooting
#

class quartermaster::syslinux (

  $tmp            = $quartermaster::params::tmp,
  $pxeroot        = $quartermaster::params::pxeroot,
  $pxecfg         = $quartermaster::params::pxecfg,
  $pxe_menu       = $quartermaster::params::pxe_menu,
  $syslinux       = $quartermaster::params::syslinux,
  $syslinux_url   = $quartermaster::params::syslinux_url,
  $syslinux_ver   = $quartermaster::params::syslinux_ver,
  $tftp_username  = $quartermaster::params::tftp_username,
  $tftp_group     = $quartermaster::params::tftp_group,
  $tftp_filemode  = $quartermaster::params::tftp_filemode,
  $www_username   = $quartermaster::params::www_username,
  $www_group      = $quartermaster::params::www_group,
  $file_mode      = $quartermaster::params::file_mode,


) inherits quartermaster::params {

  # Syslinux Staging and Extraction
  staging::deploy { "${syslinux}.tar.gz":
    source => "${syslinux_url}/${syslinux}.tar.gz",
    target  => $tmp,
    creates => "${tmp}/${syslinux}",
  }
  Tftp::File{
    owner   => $tftp_username,
    group   => $tftp_group,
    require => [
      Staging::Deploy["${syslinux}.tar.gz"],
      Tftp::File['pxelinux']
    ],
  }

  tftp::file {'pxelinux/pxelinux.0':
    source  => "${tmp}/${syslinux}/core/pxelinux.0",
  }

  tftp::file { 'pxelinux/gpxelinux0':
    source  => "${tmp}/${syslinux}/gpxe/gpxelinux.0",
  }

  tftp::file { 'pxelinux/isolinux.bin':
    source  => "${tmp}/${syslinux}/core/isolinux.bin",
  }

  tftp::file { 'pxelinux/menu.c32':
    source  => "${tmp}/${syslinux}/com32/menu/menu.c32",
  }

  tftp::file { 'pxelinux/ldlinux.c32':
    source  => "${tmp}/${syslinux}/com32/elflink/ldlinux/ldlinux.c32",
  }
  tftp::file { 'pxelinux/libutil.c32':
    source  => "${tmp}/${syslinux}/com32/libutil/libutil.c32",
  }


  concat {"${pxecfg}/default":
    owner   => $tftp_username,
    group   => $tftp_group,
    mode    => $file_mode,
  }

  concat::fragment{"default_header":
    target  => "${pxecfg}/default",
    content => template("quartermaster/pxemenu/header.erb"),
    order   => 01,
  }

  concat::fragment{"default_localboot":
    target  => "${pxecfg}/default",
    content => template("quartermaster/pxemenu/localboot.erb"),
    order   => 01,
  }


  tftp::file {'pxelinux/pxelinux.cfg/graphics_cfg':
    content =>"
menu width 80
menu margin 10
menu passwordmargin 3
menu rows 12
menu tabmsgrow 18
menu cmdlinerow 18
menu endrow 24
menu passwordrow 11
",
  }

A
A
A
A
A
A
A
A
A
A
A
A
A
A
A
A
A

}
