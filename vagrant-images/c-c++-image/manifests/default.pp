class { "java":
  distribution => 'jre',
}

package { "clang":
  ensure => 'installed',
}

package { "nasm":
  ensure => 'installed',
}

package { "gcc-multilib":
  ensure => 'installed',
}

package { "make":
  ensure => 'installed',
}

