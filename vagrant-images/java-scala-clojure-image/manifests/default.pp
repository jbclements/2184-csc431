include apt

#class { 'apt':
# always_apt_update => true,
#}

apt::ppa { 'ppa:linuxuprising/java':}

package { "oracle-java10-installer":
  ensure => 'installed',
  require => Apt::Ppa['ppa:linuxuprising/java'],
}

