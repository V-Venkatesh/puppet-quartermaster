# == Class: quartermaster::hp_spp
#
class quartermaster::hp_spp (
  $hp_spp_iso_complete_url_location = 'ftp://ftp.hp.com/pub/softlib2/software1/cd-generic/p67859018/v108240/SPP2015040.2015_0407.5.iso',
  $hp_spp_iso_name = 'SPP2015040.2015_0407.5.iso',

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

) inherits quartermaster::params {

  tftp::file{'hp_spp':
    ensure => directory,
  } ->

  file{"${wwwroot}/HP_SPP":
    ensure => directory,
  } ->
  file{"${wwwroot}/HP_SPP/iso":
    ensure => directory,
  } ->
  Exec{
    timeout => 0,
  } ->
  staging::file{'HP_SPP_ISO':
    source => $hp_spp_iso_complete_url_location,
    target => "${wwwroot}/HP_SPP/iso/${hp_spp_iso_name}",
    require =>  File["${wwwroot}/HP_SPP/iso"],
  } ->
  concat::fragment{"pxeboot_hp_spp":
    target  => "${pxecfg}/default",
    content => template("quartermaster/pxemenu/hp_spp.erb"),
    order   => 02,
  }
}