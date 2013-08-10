# manage strongswan services
class strongswan::base {

    package { 'strongswan':
      ensure  => installed,
    } ->

    exec { 'ipsec_privatekey':
      command => "certtool --generate-privkey --bits 2048 --outfile ${strongswan::cert_dir}/private/${strongswan::custom_hostname}.pem",
      creates => "${strongswan::cert_dir}/private/${strongswan::custom_hostname}.pem";
    } ->

    anchor{'strongswan::certs::done': }

    if $use_monkeysphere {

      Package['strongswan'] {
        require => Package['monkeysphere','gnutls-utils'],
      }

      exec { 'ipsec_monkeysphere_cert':
        command => "monkeysphere-host import-key ${strongswan::cert_dir}/private/${strongswan::custom_hostname}.pem ike://${strongswan::custom_hostname} && gpg --homedir /var/lib/monkeysphere/host -a --export =ike://${strongswan::custom_hostname} > ${strongswan::cert_dir}/certs/${strongswan::custom_hostname}.asc",
        creates => "${strongswan::cert_dir}/certs/${strongswan::custom_hostname}.asc",
        require => Exec['ipsec_privatekey'],
        before  => Anchor['strongswan::certs::done'],
      }
  }

  File {
    require => Package['strongswan'],
    notify  => Service['ipsec'],
    owner   => 'root',
    group   => 0,
    mode    => '0400',
  }

  $binary_name = basename($strongswan::binary)
  file{
    '/etc/ipsec.secrets':
      content => ": RSA ${strongswan::custom_hostname}.pem\n";
    # this is needed because if the glob-include in the config
    # doesn't find anything it fails.
    "${strongswan::config_dir}/hosts":
      ensure  => directory,
      purge   => true,
      force   => true,
      recurse => true;
    "${strongswan::config_dir}/hosts/__dummy__.conf":
      ensure  => 'present';
    '/etc/ipsec.conf':
      content => template($strongswan::ipsec_conf_template);
    "/usr/local/sbin/${binary_name}_connected_hosts":
      content => "#!/bin/bash\n${strongswan::binary} status | grep INSTALLED | awk -F\\{ '{ print \$1 }'\n",
      notify  => undef,
      mode    => '0500';
    "/usr/local/sbin/${binary_name}_info":
      content => template('strongswan/scripts/info.sh.erb'),
      notify  => undef,
      mode    => '0500';
    "/usr/local/sbin/${binary_name}_start_unconnected":
      content => template('strongswan/scripts/start_unconnected.sh.erb'),
      notify  => undef,
      mode    => '0500';
  }

  service { 'ipsec':
    ensure => running,
    enable => true,
  }
}
