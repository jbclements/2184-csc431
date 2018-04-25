class { 'java':
  distribution => 'jre',
}

package { "clang" :
  ensure => 'installed',
}

package { "nasm":
  ensure => 'installed',
}
