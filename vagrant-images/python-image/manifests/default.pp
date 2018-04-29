class { "java":
  distribution => 'jre',
}

package { "python3.6":
  ensure => 'installed',
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

