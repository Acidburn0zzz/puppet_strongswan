# manage a strongswan
class strongswan(
  $manage_shorewall         = false,
  $shorewall_source         = 'net',
  $monkeysphere_publish_key = false,
  $ipsec_nat                = false,
  $default_left_ip_address  = $::ipaddress,
  $additional_options       = '',
  $auto_remote_host         = false
) {

  class{'monkeysphere':
    publish_key => $monkeysphere_publish_key
  } -> class{'certtool': }

  case $::operatingsystem {
    centos: {
      case $::lsbmajdistrelease {
        '5': {
          $config_dir = '/etc/ipsec.d'
          $certdir    = '/etc/ipsec.d'

          class{'strongswan::centos::five':
            require => Class['monkeysphere'],
          }
        }
        default: {
          $config_dir = '/etc/strongswan'
          $certdir    = '/etc/strongswan/ipsec.d'
          class{'strongswan::centos::six':
            require => Class['monkeysphere'],
          }
        }
      }
    }
    default: {
      $config_dir = '/etc/ipsec.d'
      $certdir    = '/etc/ipsec.d'
      class{'strongswan::base':
        require => Class['monkeysphere'],
      }
    }
  }

  if $manage_shorewall {
    class{'shorewall::rules::ipsec':
      source => $strongswan::shorewall_source
    }
    if $ipsec_nat {
      include shorewall::rules::ipsec_nat
    }
  }
}
