include apt

#class { 'apt':
# always_apt_update => true,
#}

package { "python3.6":
  ensure => 'installed',
}

package { "clang":
  ensure => 'installed',
}

package { "nasm":
  ensure => 'installed',
}
